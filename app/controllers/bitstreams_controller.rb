# frozen_string_literal: true

##
# N.B.: This controller has no corresponding policy class. {ItemPolicy} is used
# instead.
#
class BitstreamsController < ApplicationController

  before_action :ensure_logged_in

  before_action :set_item, only: :create
  before_action :authorize_item, only: :create

  before_action :set_bitstream, only: :destroy
  before_action :authorize_bitstream, only: :destroy

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
    begin
      @bitstream.destroy!
    rescue => e
      render plain: "#{e}", status: :internal_server_error
    else
      head :no_content
    end
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