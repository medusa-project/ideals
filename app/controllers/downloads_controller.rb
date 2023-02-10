# frozen_string_literal: true

class DownloadsController < ApplicationController

  LOGGER = CustomLogger.new(DownloadsController)

  before_action :ensure_institution_host, :set_download, :authorize_download

  ##
  # Responds to `GET /downloads/:download_key/file`
  #
  def file
    if @download.filename.present?
      redirect_to @download.presigned_url,
                  status: :see_other,
                  allow_other_host: true
    else
      LOGGER.error("file(): object does not exist for download key %s",
                   @download.key)
      render plain:  "File does not exist for download #{@download.key}.",
             status: :not_found
    end
  end

  ##
  # Responds to `GET /downloads/:key`
  #
  def show
    render partial: "show"
  end


  private

  def authorize_download
    @download ? authorize(@download) : skip_authorization
  end

  def set_download
    @download = Download.find_by_key(params[:key] || params[:download_key])
    raise ActiveRecord::RecordNotFound unless @download
  end

end
