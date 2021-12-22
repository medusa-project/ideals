class RegisteredElementsController < ApplicationController

  before_action :ensure_logged_in
  before_action :set_element, only: [:edit, :update, :destroy]
  before_action :authorize_element, only: [:edit, :update, :destroy]

  ##
  # Responds to `POST /elements` (XHR only)
  #
  def create
    @element = RegisteredElement.new(registered_element_params)
    authorize @element
    begin
      @element.save!
    rescue
      render partial: "shared/validation_messages",
             locals: { object: @element },
             status: :bad_request
    else
      flash['success'] = "Element \"#{@element.name}\" created."
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
      flash['success'] = "Element \"#{@element.name}\" deleted."
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
    rescue
      render partial: "shared/validation_messages",
             locals: { object: @element },
             status: :bad_request
    else
      flash['success'] = "Element \"#{@element.name}\" updated."
      render "shared/reload"
    end
  end

  private

  def registered_element_params
    params.require(:registered_element).permit(:input_type, :institution_id,
                                               :label, :name, :scope_note,
                                               :uri, :vocabulary_key)
  end

  def set_element
    @element = RegisteredElement.find_by_name(params[:name])
    raise ActiveRecord::RecordNotFound unless @element
    @breadcrumbable = @element
  end

  def authorize_element
    @element ? authorize(@element) : skip_authorization
  end

end
