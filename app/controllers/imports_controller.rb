class ImportsController < ApplicationController

  before_action :ensure_logged_in
  before_action :set_import, except: [:create, :index, :new]
  before_action :authorize_import, except: [:create, :index, :new]

  ##
  # Responds to `POST /imports`
  #
  def create
    authorize Import
    @import      = Import.new(sanitized_params)
    @import.user = current_user
    begin
      @import.save!
    rescue => e
      render partial: "shared/validation_messages",
             locals: { object: @import.errors.any? ? @import : e },
             status: :bad_request
    else
      flash['success'] = "Import created."
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
      where("created_at > ?", 6.months.ago).
      order(created_at: :desc)
    respond_to do |format|
      format.js
      format.html
    end
  end

  ##
  # Returns content for the create-import form.
  #
  # Responds to `GET /imports/new` (XHR only)
  #
  def new
    authorize Import
    @import = Import.new
    render partial: "imports/import_form"
  end

  ##
  # Responds to `GET /imports/:id`
  #
  def show
    render partial: "show"
  end

  ##
  # Responds to `PUT/PATCH /imports/:id`
  #
  def update # TODO: rename to complete or something
    ImportJob.perform_later(@import, current_user)
    flash['success'] = "The files have been uploaded, and the import will "\
                       "begin momentarily."
    render "shared/reload"
  end

  ##
  # Receives a file uploaded via the "Edit Import" a.k.a. "Upload Package"
  # form, writing it to the application S3 bucket.
  #
  # The request must include an `X-Relative-Path` header containing the path of
  # the uploaded file relative to the package root.
  #
  # Responds to `POST /imports/:id/upload-file`
  #
  def upload_file
    relative_path = request.headers['X-Relative-Path']
    if relative_path.blank?
      render plain:  "X-Relative-Path header not provided",
             status: :bad_request and return
    end
    @import.upload_file(relative_path: relative_path,
                        io:            request.env['rack.input'])
    head :no_content
  end


  private

  def sanitized_params
    params.require(:import).permit(:collection_id, :user_id)
  end

  def set_import
    @import = Import.find(params[:id] || params[:import_id])
  end

  def authorize_import
    @import ? authorize(@import) : skip_authorization
  end

end
