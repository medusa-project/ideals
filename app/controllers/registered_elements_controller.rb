# frozen_string_literal: true

class RegisteredElementsController < ApplicationController

  before_action :ensure_institution_host, :ensure_logged_in
  before_action :set_element, only: [:edit, :update, :destroy]
  before_action :authorize_element, only: [:edit, :update, :destroy]
  before_action :store_location, only: :index

  ##
  # Responds to `POST /elements` (XHR only)
  #
  def create
    @element             = RegisteredElement.new(registered_element_params)
    @element.institution = current_institution
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
      redirect_back fallback_location: registered_elements_path
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
  # Responds to `GET /elements`
  #
  def index
    authorize RegisteredElement
    institution  = current_institution
    @elements    = RegisteredElement.where(institution: institution).order(:name)
    @new_element = RegisteredElement.new(institution: institution)
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
    params.require(:registered_element).permit(:highwire_mapping, :input_type,
                                               :label, :name, :scope_note, :uri,
                                               :vocabulary_id)
  end

  def set_element
    @element = RegisteredElement.find_by(name:        params[:name],
                                         institution: current_institution)
    raise ActiveRecord::RecordNotFound unless @element
  end

  def authorize_element
    @element ? authorize(@element) : skip_authorization
  end

end
