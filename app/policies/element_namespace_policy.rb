# frozen_string_literal: true

class ElementNamespacePolicy < ApplicationPolicy

  WRONG_SCOPE_RESULT = {
    authorized: false,
    reason:     "This element namespace resides in a different institution."
  }

  ##
  # @param request_context [RequestContext]
  # @param element_namespace [ElementNamespace]
  #
  def initialize(request_context, element_namespace)
    @user            = request_context&.user
    @ctx_institution = request_context&.institution
    @role_limit      = request_context&.role_limit || Role::NO_LIMIT
    @namespace       = element_namespace
  end

  def clone
    if effective_sysadmin?(@user, @role_limit)
      return AUTHORIZED_RESULT
    elsif @ctx_institution != @namespace.institution
      return WRONG_SCOPE_RESULT
    end
    effective_institution_admin(@user, @namespace.institution, @role_limit)
  end

  def create
    effective_institution_admin(@user, @ctx_institution, @role_limit)
  end

  def destroy
    if effective_sysadmin?(@user, @role_limit)
      return AUTHORIZED_RESULT
    elsif @ctx_institution != @namespace.institution
      return WRONG_SCOPE_RESULT
    end
    effective_institution_admin(@user, @namespace.institution, @role_limit)
  end

  def edit
    update
  end

  def index
    effective_institution_admin(@user, @ctx_institution, @role_limit)
  end

  def new
    create
  end

  def show
    update
  end

  def update
    if !@user
      return LOGGED_OUT_RESULT
    elsif effective_sysadmin?(@user, @role_limit)
      return AUTHORIZED_RESULT
    elsif @ctx_institution != @namespace.institution
      return WRONG_SCOPE_RESULT
    end
    effective_institution_admin(@user, @namespace.institution, @role_limit)
  end
end
