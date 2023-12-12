# frozen_string_literal: true

##
# # How imports work
#
# 1. Before any uploading happens, the client creates an {Import} instance
#    representing the import, which is associated with a {Collection} into
#    which files are to be imported.
# 2. In the UI, there is a file input accepting either a compressed file (for
#    packages) or a CSV file. When the input receives a file:
#      1. An XHR PATCH request is made to {update} containing its name and
#         length.
#      2. An XHR GET request is made to {show}. The response contains a JSON
#         representation of the {Import}, which contains a presigned S3 URL to
#         upload to.
#      3. The client uploads the file to this URL.
#      4. When the upload is complete, the client invokes {complete_upload},
#         which invokes an {ImportJob} to work asynchronously.
#      5. After the import has finished (successfully or not), the import
#         package is deleted.
#
class ImportsController < ApplicationController

  before_action :ensure_institution_host, :ensure_logged_in
  before_action :set_import, except: [:create, :index, :new]
  before_action :authorize_import, except: [:create, :index, :new]
  before_action :store_location, only: :index

  ##
  # Responds to `POST /imports/:id/complete-upload`
  #
  def complete_upload
    ImportJob.perform_later(import: @import, user: current_user)
    toast!(title:   "File uploaded",
           message: "The file has been uploaded. The import will commence "\
             "momentarily.")
    # The page will reload via JS.
  end

  ##
  # Responds to `POST /imports`
  #
  def create
    @import      = Import.new(import_params)
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
    @import = Import.new(import_params)
    render partial: "imports/import_form"
  end

  ##
  # Responds to `GET /imports/:id`
  #
  def show
    if request.format == :json
      render "show"
    else
      render partial: "show"
    end
  end

  ##
  # Responds to `PUT/PATCH /imports/:id`
  #
  def update
    begin
      @import.task = Task.create!(name: ImportJob.to_s)
      @import.update!(import_params)
    rescue => e
      render partial: "shared/validation_messages",
             locals: { object: @import.errors.any? ? @import : e },
             status: :bad_request
    else
      head :no_content
    end
  end


  private

  def import_params
    params.require(:import).permit(:collection_id, :filename,
                                   :institution_id, :length, :user_id)
  end

  def set_import
    @import = Import.find(params[:id] || params[:import_id])
  end

  def authorize_import
    @import ? authorize(@import) : skip_authorization
  end

end
