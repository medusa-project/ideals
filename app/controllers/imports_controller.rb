# frozen_string_literal: true

##
# # How imports work
#
# Before any uploading happens, a new {Import} instance is created representing
# the import. The import is associated with a {Collection} into which files
# are being imported.
#
# In the UI, there is a file input accepting either a compressed file (for
# packages) or a CSV file can be dropped. {upload_file} receives the file,
# stores it on the file system, and invokes an {ImportJob} to work
# asynchronously on the import using whatever importer it deems necessary
# ({CsvImporter}, {SafImporter}, etc.)
#
# After the import has succeeded, the import package is deleted.
#
class ImportsController < ApplicationController

  before_action :ensure_institution_host, :ensure_logged_in
  before_action :set_import, except: [:create, :index, :new]
  before_action :authorize_import, except: [:create, :index, :new]
  before_action :store_location, only: :index

  ##
  # Responds to `POST /imports`
  #
  def create
    @import      = Import.new(sanitized_params)
    @import.user = current_user
    authorize @import
    begin
      @import.save!
    rescue => e
      render partial: "shared/validation_messages",
             locals: { object: @import.errors.any? ? @import : e },
             status: :bad_request
    else
      toast!(title:   "Import created",
             message: "An import has been created. Click its upload button "\
                      "to add files to it.")
      render "shared/reload"
    end
  end

  ##
  # Deletes all files associated with an import from the application S3 bucket.
  # This should be done before a new batch is uploaded.
  #
  # Responds to `POST /imports/:id/delete_all_files`
  #
  def delete_all_files
    @import.delete_all_files
    head :no_content
  end

  ##
  # Returns content for the "upload package" form.
  #
  # Responds to `GET /imports/:id/edit` (XHR only)
  #
  def edit
    render partial: "imports/upload_package_form"
  end

  ##
  # Responds to `GET /imports`
  #
  def index
    authorize Import
    @imports = Import.
      where(institution: current_institution).
      where("created_at > ?", 6.months.ago).
      order(created_at: :desc)
    respond_to do |format|
      format.js
      format.html
    end
  end

  ##
  # Returns content for the create-import form.
  # Responds to `GET /imports/new` (XHR only).
  #
  # The following query arguments are required:
  #
  # * `institution_id`: ID of the owning institution.
  #
  def new
    authorize Import
    if params.dig(:import, :institution_id).blank?
      render plain: "Missing institution ID", status: :bad_request
      return
    end
    @import = Import.new(sanitized_params)
    render partial: "imports/import_form"
  end

  ##
  # Responds to `GET /imports/:id`
  #
  def show
    render partial: "show"
  end

  ##
  # Receives a file uploaded via the "Edit Import" a.k.a. "Upload Package"
  # form, writing it to a temporary location on the file system. (It may be
  # a compressed file that will need to get unzipped).
  #
  # Responds to `POST /imports/:id/upload-file` (XHR only).
  #
  def upload_file
    @import.save_file(file:     params[:file],
                      filename: params[:file].original_filename)
    # (waiting for the file to upload)
    ImportJob.perform_later(import: @import, user: current_user)
    toast!(title:   "Files uploaded",
           message: "The files have been uploaded. The import will commence "\
                    "momentarily.")
    # The page will reload via JS.
  end


  private

  def sanitized_params
    params.require(:import).permit(:collection_id, :institution_id, :user_id)
  end

  def set_import
    @import = Import.find(params[:id] || params[:import_id])
  end

  def authorize_import
    @import ? authorize(@import) : skip_authorization
  end

end
