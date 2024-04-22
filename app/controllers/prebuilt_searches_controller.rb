# frozen_string_literal: true

class PrebuiltSearchesController < ApplicationController

  before_action :ensure_institution_host
  before_action :ensure_logged_in
  before_action :set_prebuilt_search, except: [:create, :index, :new]
  before_action :authorize_prebuilt_search, except: [:create, :index, :new]
  before_action :store_location, only: [:index, :show]

  ##
  # Responds to `POST /prebuilt-searches`
  #
  def create
    authorize PrebuiltSearch
    @prebuilt_search = PrebuiltSearch.new(permitted_params)
    begin
      @prebuilt_search.save!
      build_elements
    rescue => e
      render partial: "shared/validation_messages",
             locals: { object: @prebuilt_search.errors.any? ? @prebuilt_search : e },
             status: :bad_request
    else
      toast!(title:   "Prebuilt search created",
             message: "Prebuilt search \"#{@prebuilt_search.name}\" has been created.")
      render "shared/reload"
    end
  end

  ##
  # Responds to `DELETE /prebuilt-searches/:id`
  #
  def destroy
    institution = @prebuilt_search.institution
    begin
      @prebuilt_search.destroy!
    rescue => e
      flash['error'] = "#{e}"
    else
      toast!(title:   "Prebuilt search deleted",
             message: "Prebuilt search \"#{@prebuilt_search.name}\" has been deleted.")
    ensure
      if current_user_is_sysadmin?
        redirect_to institution_path(institution)
      else
        redirect_to prebuilt_searches_path
      end
    end
  end

  ##
  # Returns content for the edit-prebuilt-search form.
  #
  # Responds to `GET /prebuilt-searches/:id/edit` (XHR only)
  #
  def edit
    render partial: "form"
  end

  ##
  # Responds to `GET /prebuilt-searches`
  #
  def index
    authorize PrebuiltSearch
    @prebuilt_searches = PrebuiltSearch.
      where(institution: current_institution).
      order(:name)
  end

  ##
  # Returns content for the create-prebuilt-search form.
  #
  # Responds to `GET /prebuilt-searches/new` (XHR only)
  #
  # The following query arguments are accepted:
  #
  # * `institution_id`: ID of the owning institution.
  #
  def new
    authorize PrebuiltSearch
    if params.dig(:prebuilt_search, :institution_id).blank?
      render plain: "Missing institution ID", status: :bad_request
      return
    end
    @prebuilt_search = PrebuiltSearch.new(permitted_params)
    render partial: "form"
  end

  ##
  # Responds to `GET /prebuilt-searches/:id`
  #
  def show
  end

  ##
  # Responds to `PUT/PATCH /prebuilt-searches/:id`
  #
  def update
    begin
      @prebuilt_search.update!(permitted_params)
      build_elements
    rescue => e
      render partial: "shared/validation_messages",
             locals: { object: @prebuilt_search.errors.any? ? @prebuilt_search : e },
             status: :bad_request
    else
      toast!(title:   "Prebuilt search updated",
             message: "Prebuilt search \"#{@prebuilt_search.name}\" has been updated.")
      render "shared/reload"
    end
  end


  private

  def permitted_params
    params.require(:prebuilt_search).permit(:direction, :institution_id, :name,
                                            :ordering_element_id)
  end

  def set_prebuilt_search
    @prebuilt_search = PrebuiltSearch.find(params[:id] || params[:prebuilt_search_id])
    @breadcrumbable  = @prebuilt_search
  end

  def authorize_prebuilt_search
    @prebuilt_search ? authorize(@prebuilt_search) : skip_authorization
  end

  def build_elements
    if params[:prebuilt_search_elements].respond_to?(:each)
      @prebuilt_search.elements.destroy_all
      params[:prebuilt_search_elements].each do |element_params|
        next if element_params[:term].blank?
        @prebuilt_search.elements.build(registered_element_id: element_params[:registered_element_id],
                                        term:                  element_params[:term])
      end
      @prebuilt_search.save!
    end
  end

end
