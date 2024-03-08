# frozen_string_literal: true

class RegisteredElementsController < ApplicationController

  before_action :ensure_institution_host, :ensure_logged_in
  before_action :set_element, only: [:edit, :update, :destroy]
  before_action :authorize_element, only: [:edit, :update, :destroy]
  before_action :store_location, only: [:index, :index_template]

  ##
  # Responds to `POST /elements` (XHR only)
  #
  def create
    @element = RegisteredElement.new(registered_element_params)
    authorize @element
    begin
      @element.save!
    rescue => e
      render partial: "shared/validation_messages",
             locals: { object: @element.errors.any? ? @element : e },
             status: :bad_request
    else
      toast!(title:   "Element created",
             message: "The element \"#{@element.name}\" has been created.")
      render "shared/reload"
    end
  end

  ##
  # Responds to `DELETE /elements/:name`
  #
  def destroy
    institution = @element.institution
    begin
      @element.destroy!
    rescue ActiveRecord::InvalidForeignKey
      flash['error'] = "The #{@element.name} element cannot be deleted, as "\
                       "it is in use by one or more items."
    rescue => e
      flash['error'] = "#{e}"
    else
      toast!(title:   "Element deleted",
             message: "The element \"#{@element.name}\" has been deleted.")
    ensure
      if current_user_is_sysadmin?
        if institution
          redirect_to institution_path(institution)
        else
          redirect_to template_elements_path
        end
      else
        redirect_to registered_elements_path
      end
    end
  end

  ##
  # Responds to `GET /elements/:name` (XHR only)
  #
  def edit
    render partial: 'registered_elements/form',
           locals: { element: @element }
  end

  ##
  # Displays a list of all of an institution's registered elements.
  #
  # Responds to `GET /elements`.
  #
  def index
    authorize RegisteredElement
    institution           = current_institution
    @elements             = RegisteredElement.where(institution: institution).order(:label)
    @unaccounted_prefixes = institution.registered_element_prefixes -
      institution.element_namespaces.map(&:prefix)
  end

  ##
  # Displays a list of all template elements to sysadmins only.
  #
  # Responds to `GET /template-elements`.
  #
  def index_template
    authorize RegisteredElement
    @elements = RegisteredElement.where(template: true).order(:name)
  end

  ##
  # Responds to `GET /elements/new` (XHR only).
  #
  # The following query arguments are accepted:
  #
  # * `institution_id`: ID of the owning institution.
  #
  def new
    authorize RegisteredElement
    @element = RegisteredElement.new(registered_element_params)
    render partial: "form"
  end

  ##
  # Responds to `PATCH /elements/:name` (XHR only)
  #
  def update
    begin
      @element.update!(registered_element_params)
    rescue => e
      render partial: "shared/validation_messages",
             locals: { object: @element.errors.any? ? @element : e },
             status: :bad_request
    else
      toast!(title:   "Element updated",
             message: "The element \"#{@element.name}\" has been updated.")
      render "shared/reload"
    end
  end


  private

  def registered_element_params
    params.require(:registered_element).permit(:dublin_core_mapping,
                                               :highwire_mapping, :input_type,
                                               :institution_id, :label, :name,
                                               :scope_note, :template, :uri,
                                               :vocabulary_id)
  end

  def set_element
    @element = RegisteredElement.find(params[:id])
    raise ActiveRecord::RecordNotFound unless @element
  end

  def authorize_element
    @element ? authorize(@element) : skip_authorization
  end

end
