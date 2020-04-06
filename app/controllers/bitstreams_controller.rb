# frozen_string_literal: true

##
# N.B.: This controller has no corresponding policy class. {ItemPolicy} is used
# instead.
#
class BitstreamsController < ApplicationController

  LOGGER = CustomLogger.new(BitstreamsController)

  before_action :ensure_logged_in, except: :show

  before_action :set_item, only: :create
  before_action :authorize_item, only: :create

  before_action :set_bitstream, only: [:destroy, :show]
  before_action :authorize_bitstream, only: [:destroy, :show]

  ##
  # Accepts raw files (i.e. not `multipart/form-data`) via the file upload
  # feature of the submission form. The accepted files are streamed into the
  # application S3 bucket and associated with new {Bitstream}s which are in
  # turn associated with a parent {Item}.
  #
  # Responds to `POST /items/:item_id/bitstreams`
  #
  def create
    bs = nil
    begin
      io = request.env['rack.input']
      if io
        ActiveRecord::Base.transaction do
          filename = request.env['HTTP_X_FILENAME']
          length   = request.env['HTTP_X_CONTENT_LENGTH'].to_i
          bs       = Bitstream.new_in_staging(@item, filename, length)
          bs.upload_to_staging(io)
          bs.save!
        end
      end
    rescue => e
      render plain: "#{e}", status: :internal_server_error
    else
      response.header['Location'] = item_bitstream_url(@item, bs)
      head :created
    end
  end

  ##
  # Deletes {Bitstream}s via the file table in the submission form.
  #
  # Responds to `DELETE /items/:item_id/bitstreams/:id`
  #
  def destroy
    @bitstream.destroy!
    head :no_content
  end

  ##
  # Returns a bitstream's data.
  #
  # Responds to `GET /items/:item_id/bitstreams/:id`
  #
  def show
    s3_request = {
        bucket: @bitstream.item.in_archive ? "" : # TODO: in_archive
                    ::Configuration.instance.aws[:bucket],
        key:    @bitstream.key
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
      object[:range]                    = sprintf("bytes=%d-%d",
                                                  start_offset, end_offset)
    end

    LOGGER.debug('show(): requesting %s', s3_request)

    client      = Aws::S3::Client.new
    s3_response = client.head_object(s3_request)

    response.status                         = status
    response.headers['Content-Type']        = @bitstream.media_type
    response.headers['Content-Disposition'] = "attachment; filename=#{@bitstream.original_filename}"
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

  private

  def authorize_bitstream
    @bitstream ? authorize(@bitstream.item, policy_class: ItemPolicy) :
        skip_authorization
  end

  def authorize_item
    @item ? authorize(@item, policy_class: ItemPolicy) :
        skip_authorization
  end

  def set_bitstream
    @bitstream = Bitstream.find(params[:id]) if params[:id]
  end

  def set_item
    @item = Item.find(params[:item_id]) if params[:item_id]
  end

end