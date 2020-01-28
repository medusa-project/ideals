class RegisteredElementsController < ApplicationController

  PERMITTED_PARAMS = [:name, :scope_note]

  before_action :authorize_user

  ##
  # Responds to POST /elements XHR only)
  #
  def create
    @element = RegisteredElement.new(sanitized_params)
    begin
      @element.save!
    rescue
      render partial: 'shared/validation_messages',
             locals: { object: @element },
             status: :bad_request
    else
      flash['success'] = "Element \"#{@element.name}\" created."
      render 'create' # create.js.erb will reload the page
    end
  end

  ##
  # Responds to DELETE /elements/:name
  #
  def destroy
    element = RegisteredElement.find_by_name(params[:name])
    raise ActiveRecord::RecordNotFound unless element
    begin
      element.destroy!
    rescue => e
      flash['error'] = "#{e}"
    else
      flash['success'] = "Element \"#{element.name}\" deleted."
    ensure
      redirect_back fallback_location: registered_elements_path
    end
  end

  ##
  # Responds to GET /elements/:name (XHR only)
  #
  def edit
    element = RegisteredElement.find_by_name(params[:name])
    raise ActiveRecord::RecordNotFound unless element

    render partial: 'registered_elements/form',
           locals: { element: element, context: :edit }
  end

  ##
  # Responds to GET /elements
  #
  def index
    @elements = RegisteredElement.all.order(:name)
    @new_element = RegisteredElement.new
  end

  ##
  # Responds to PATCH /elements/:name (XHR only)
  #
  def update
    element = RegisteredElement.find_by_name(params[:name])
    raise ActiveRecord::RecordNotFound unless element
    begin
      element.update!(sanitized_params)
    rescue
      render partial: 'shared/validation_messages',
             locals: { object: element },
             status: :bad_request
    else
      flash['success'] = "Element \"#{element.name}\" updated."
      render 'update' # update.js.erb will reload the page
    end
  end

  private

  def sanitized_params
    params.require(:registered_element).permit(PERMITTED_PARAMS)
  end

end
