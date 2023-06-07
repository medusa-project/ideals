# frozen_string_literal: true

class ElementNamespacesController < ApplicationController

  before_action :ensure_institution_host, :ensure_logged_in
  before_action :set_namespace, except: [:create, :index, :new]
  before_action :authorize_namespace, except: [:create, :index]

  ##
  # Responds to `POST /element-namespaces` (XHR only)
  #
  def create
    @namespace = ElementNamespace.new(element_namespace_params)
    authorize @namespace
    begin
      @namespace.save!
    rescue => e
      render partial: "shared/validation_messages",
             locals: { object: @namespace.errors.any? ? @namespace : e },
             status: :bad_request
    else
      toast!(title:   "Namespace created",
             message: "The element namespace \"#{@namespace}\" has been "\
                      "created.")
      render "shared/reload"
    end
  end

  ##
  # Responds to `DELETE /element-namespaces/:id`
  #
  def destroy
    institution = @namespace.institution
    begin
      @namespace.destroy!
    rescue => e
      flash['error'] = "#{e}"
    else
      toast!(title:   "Namespace deleted",
             message: "The element namespace \"#{@namespace}\" has been "\
                      "deleted.")
    ensure
      if current_user.sysadmin?
        redirect_to institution_path(institution)
      else
        redirect_to element_namespaces_path
      end
    end
  end

  ##
  # Responds to `GET /element-namespaces/:id/edit`
  #
  def edit
    render partial: "element_namespaces/form",
           locals: { namespace: @namespace }
  end

  ##
  # Responds to `GET /element-namespaces`
  #
  def index
    authorize ElementNamespace
    @namespaces           = current_institution.element_namespaces.order(:prefix)
    @unaccounted_prefixes = current_institution.registered_element_prefixes -
      @namespaces.map(&:prefix)
  end

  ##
  # Responds to `GET /element-namespaces/new`
  #
  # The following query arguments are accepted:
  #
  # * `institution_id`: ID of the owning institution.
  #
  def new
    authorize ElementNamespace
    if params.dig(:element_namespace, :institution_id).blank?
      render plain: "Missing institution ID", status: :bad_request
      return
    end
    @namespace = ElementNamespace.new(element_namespace_params)
    render partial: "form"
  end

  ##
  # Responds to `PATCH /element-namespace/:id` (XHR only)
  #
  def update
    begin
      @namespace.update!(element_namespace_params)
    rescue => e
      render partial: "shared/validation_messages",
             locals: { object: @namespace.errors.any? ? @namespace : e },
             status: :bad_request
    else
      toast!(title:   "Namespace updated",
             message: "The element namespace \"#{@namespace}\" has been "\
                      "updated.")
      render "shared/reload"
    end
  end


  private

  def element_namespace_params
    params.require(:element_namespace).permit(:institution_id, :prefix, :uri)
  end

  def set_namespace
    @namespace = ElementNamespace.find(params[:id] || params[:element_namespace_id])
  end

  def authorize_namespace
    @namespace ? authorize(@namespace) : skip_authorization
  end

end
