# frozen_string_literal: true

##
# # Uploads
#
# File upload is a three-step process:
#
# 1. A new {Bitstream} instance is created via {create}, with `filename` and
#    `length` properties set.
# 2. The client retrieves the JSON representation of that instance, which
#    contains a presigned object URL, via {show}.
# 3. The client sends data to the object URL via HTTP PUT.
#
# # Downloads
#
# Bitstreams can be downloaded in two ways:
#
# 1. By proxying them through the application via {data}. This is not advised,
#    as it ties up a request connection.
# 2. By redirecting to a presigned S3 URL using {object}.
#
# Bitstreams do not have public URLs because they do not have public-read ACLs.
# (Some non-bitstream objects in the application bucket do have such ACLs, such
# as the theme images.)
#
# ## Statistics
#
# Every time a {Bitstream} is "downloaded," an {Event} of type
# {Event::Type::DOWNLOAD} is supposed to get ascribed to it, which effectively
# increments its download count. But what is considered a download?
#
# 1. Downloading a single bitstream using a download button?
# 2. Downloading a zip file full of bitstreams using a download button?
# 3. Loading a bitstream or its representation into the main item viewer?
# 4. Receiving a request for a pre-signed URL to the bitstream's content via
#    {object}?
# 5. Streaming a bitstream's content through via {data}?
#     a. Are multiple ranged requests to {data} all considered independent
#        downloads? Or only non-ranged requests?
#
# It turns out that we are considering only #1 and #2 to be downloads, so
# caveat emptor about download statistics.
#
class BitstreamsController < ApplicationController

  LOGGER = CustomLogger.new(BitstreamsController)

  before_action :ensure_institution_host
  before_action :ensure_logged_in, except: [:data, :index, :object, :show,
                                            :viewer]

  before_action :set_item, only: [:create, :index]
  before_action :set_bitstream, except: [:create, :index]
  before_action :authorize_item, only: :index
  before_action :authorize_bitstream, except: [:create, :index]

  rescue_from Aws::S3::Errors::InvalidRange, with: :rescue_invalid_range

  ##
  # Creates a new bitstream in the staging area.
  #
  # Responds to `POST /items/:item_id/bitstreams`
  #
  def create
    begin
      bs = nil
      ActiveRecord::Base.transaction do
        UpdateItemCommand.new(item:        @item,
                              user:        current_user,
                              description: "Added an associated bitstream.").execute do
          bs = Bitstream.new_in_staging(item:     @item,
                                        filename: bitstream_params[:filename].gsub(/[\/\\]/, "_"),
                                        length:   bitstream_params[:length])
          bs.save!
        end
      end
      response.header['Location'] = item_bitstream_url(@item, bs)
      head :created
    rescue => e
      render plain: "#{e}", status: :bad_request
    end
  end

  ##
  # Retrieves a bitstream's data by proxying the S3 bucket. This is not very
  # efficient but may be useful or necessary in some cases. Generally, {object}
  # is preferred, as it will redirect to the S3 object, thereby not tying up a
  # request connection.
  #
  # Responds to `GET /items/:item_id/bitstreams/:id/data`.
  #
  # @see object
  #
  def data
    if @bitstream.permanent_key.present?
      key = @bitstream.permanent_key
    elsif @bitstream.staging_key.present?
      key = @bitstream.staging_key
    else
      Rails.logger.warn("Bitstream ID #{@bitstream.id} has no corresponding storage object")
      render plain:  "This bitstream has no corresponding storage object.",
             status: :not_found
      return
    end

    s3_request = {
      bucket: ::Configuration.instance.storage[:bucket],
      key:    key
    }

    if !request.headers['Range']
      status = "200 OK"
    else
      status       = "206 Partial Content"
      start_offset = 0
      length       = @bitstream.length
      end_offset   = length - 1
      match        = request.headers['Range'].match(/bytes=(\d+)-(\d*)/)
      if match
        start_offset = match[1].to_i
        end_offset   = match[2].to_i if match[2]&.present?
      end
      response.headers['Content-Range'] = sprintf("bytes %d-%d/%d",
                                                  start_offset, end_offset, length)
      s3_request[:range]                = sprintf("bytes=%d-%d",
                                                  start_offset, end_offset)
    end

    LOGGER.debug('show(): requesting %s', s3_request)

    client      = S3Client.instance
    s3_response = client.head_object(s3_request.except(:range))

    response.status                         = status
    response.headers['Content-Type']        = @bitstream.media_type
    response.headers['Content-Disposition'] = params[:'response-content-disposition'] ||
      download_content_disposition
    response.headers['Content-Length']      = s3_response.content_length.to_s
    response.headers['Last-Modified']       = s3_response.last_modified.utc.strftime("%a, %d %b %Y %T GMT")
    response.headers['Cache-Control']       = "public, must-revalidate, max-age=0"
    response.headers['Accept-Ranges']       = "bytes"

    client.get_object(s3_request) do |chunk|
      response.stream.write chunk
    end
  rescue ActionController::Live::ClientDisconnected => e
    # Rescue this or else Rails will log it at error level.
    LOGGER.debug('show(): %s', e)
  ensure
    response.stream.close
  end

  ##
  # Deletes {Bitstream}s via the file table in the submission form.
  #
  # Responds to `DELETE /items/:item_id/bitstreams/:id`
  #
  def destroy
    UpdateItemCommand.new(item:        @bitstream.item,
                          user:        current_user,
                          description: "Deleted an associated bitstream.").execute do
      @bitstream.destroy!
    end
    head :no_content
  end

  ##
  # Used for editing bitstream properties.
  #
  # Responds to GET `/items/:item_id/bitstreams/:id/edit` (XHR only)
  #
  def edit
    raise ActiveRecord::RecordNotFound unless request.xhr?
    render partial: "bitstreams/edit_form",
           locals: { bitstream: @bitstream }
  end

  ##
  # Responds to `GET /items/:item_id/bitstreams`
  #
  def index
    respond_to do |format|
      format.zip do
        bitstreams = policy_scope(@item.bitstreams,
                                  owning_item:        @item,
                                  policy_scope_class: BitstreamPolicy::Scope)
        if bitstreams.any?
          bitstreams.each do |bs|
            bs.add_download(user: current_user)
          end
          download = Download.create!(ip_address:  request.remote_ip,
                                      institution: current_institution)
          ZipBitstreamsJob.perform_later(bitstreams: bitstreams.to_a,
                                         download:   download,
                                         item_id:    @item.id,
                                         user:       current_user)
          redirect_to download_url(download)
        else
          head :no_content
        end
      end
    end
  end

  ##
  # Ingests a bitstream into Medusa.
  #
  # Responds to `POST /items/:item_id/bitstreams/:id/ingest`
  #
  def ingest
    @bitstream.ingest_into_medusa
  rescue ArgumentError => e
    render plain: "#{e}", status: :bad_request
  else
    head :no_content
  end

  ##
  # Creates a presigned URL for downloading the {Bitstream} and redirects to it
  # via HTTP 307.
  #
  # If a `dl=1` query argument is supplied, a download event is ascribed to
  # the bitstream.
  #
  # Responds to `GET /items/:item_id/bitstreams/:id/object`.
  #
  # @see data
  #
  def object
    url = @bitstream.presigned_download_url(content_disposition: download_content_disposition)
    if url
      @bitstream.add_download(user: current_user) if params[:dl] == "1"
      redirect_to url,
                  status:           :temporary_redirect,
                  allow_other_host: true
    else
      render plain:  "This bitstream has no corresponding storage object.",
             status: :not_found
    end
  rescue IOError => e
    render plain: "#{e}", status: :not_found
  end

  ##
  # Returns a bitstream's properties (in JSON format only).
  #
  # Responds to `GET /items/:item_id/bitstreams/:id`
  #
  def show
    render formats: :json
  end

  ##
  # Responds to `PATCH/PUT /items/:id/bitstreams/:id`
  #
  def update
    begin
      UpdateItemCommand.new(item: @bitstream.item,
                            user: current_user,
                            description: "Updated an associated bitstream.").execute do
        @bitstream.update!(bitstream_params)
      end
    rescue => e
      render partial: "shared/validation_messages",
             locals: { object: @bitstream.errors.any? ? @bitstream : e },
             status: :bad_request
    else
      toast!(title:   "File updated",
             message: "File \"#{@bitstream.filename}\" has been updated.")
      render "shared/reload"
    end
  end

  ##
  # Returns HTML for the item bitstream viewer (the right pane of the item
  # navigator) via XHR.
  #
  # Responds to `GET /items/:item_id/bitstreams/:id/viewer` (XHR only)
  #
  def viewer
    render partial: "bitstreams/viewer"
    # An error here will be fairly common, such as in the case of e.g. a
    # bitstream for which there is no underlying storage object. We want to
    # avoid the default error handling in this case, which would cause the
    # administrator to get swamped with email notifications.
  rescue => e
    Rails.logger.warn("#{e}")
    render plain: "Error: #{e}", status: :internal_server_error
  end


  private

  def authorize_bitstream
    @bitstream ? authorize(@bitstream) : skip_authorization
  end

  def authorize_item
    @item ? authorize(@item,
                      policy_class:  ItemPolicy,
                      policy_method: :show) : skip_authorization
  end

  def bitstream_params
    params.require(:bitstream).permit(:bundle, :bundle_position, :description,
                                      :filename, :length, :primary, :role)
  end

  def download_content_disposition
    utf8_filename  = @bitstream.filename
    ascii_filename = utf8_filename.gsub(/[^[:ascii:]]*/, '_')
    # N.B.: CGI.escape() inserts "+" instead of "%20" which Chrome interprets
    # literally.
    "attachment; filename=\"#{ascii_filename.gsub('"', "'")}\"; "\
      "filename*=UTF-8''#{ERB::Util.url_encode(utf8_filename)}"
  end

  def rescue_invalid_range
    render plain: "Invalid range.", status: :bad_request
  end

  def set_bitstream
    @bitstream = Bitstream.find(params[:id] || params[:bitstream_id])
  end

  def set_item
    @item = Item.find(params[:item_id]) if params[:item_id]
  end

end