# frozen_string_literal: true

class RegisteredElementPolicy < ApplicationPolicy

  WRONG_SCOPE_RESULT = {
    authorized: false,
    reason:     "This element resides in a different institution."
  }

  ##
  # @param request_context [RequestContext]
  # @param registered_element [RegisteredElement]
  #
  def initialize(request_context, registered_element)
    super(request_context)
    @element = registered_element
  end

  def create
    effective_institution_admin(@user, @ctx_institution, @role_limit)
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

  def index_template
    effective_sysadmin(@user, @role_limit)
  end

  def new
    create
  end

  def show
    update
  end

  def update
    if effective_sysadmin?(@user, @role_limit)
      return AUTHORIZED_RESULT
    elsif @ctx_institution != @element.institution
      return WRONG_SCOPE_RESULT
    end
    effective_institution_admin(@user, @element.institution, @role_limit)
  end
end
