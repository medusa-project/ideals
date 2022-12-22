class RegisteredElementPolicy < ApplicationPolicy

  attr_reader :user, :ctx_institution, :role, :registered_element

  ##
  # @param request_context [RequestContext]
  # @param registered_element [RegisteredElement]
  #
  def initialize(request_context, registered_element)
    @user               = request_context&.user
    @ctx_institution    = request_context&.institution
    @role               = request_context&.role_limit
    @registered_element = registered_element
  end

  def create
    effective_institution_admin(user, ctx_institution, role)
  end

  def destroy
    update
  end

  def edit
    update
  end

  def index
    create
  end

  def new
    create
  end

  def show
    update
  end

  def update
    result = effective_institution_admin(user, ctx_institution, role)
    result[:authorized] ?
      effective_institution_admin(user, registered_element.institution, role) :
      result
  end
end
