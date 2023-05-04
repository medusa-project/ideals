# frozen_string_literal: true

class PrebuiltSearchPolicy < ApplicationPolicy

  WRONG_SCOPE_RESULT = {
    authorized: false,
    reason:     "This prebuilt search resides in a different institution."
  }

  ##
  # @param request_context [RequestContext]
  # @param prebuilt_search [PrebuiltSearch]
  #
  def initialize(request_context, prebuilt_search)
    @user            = request_context&.user
    @ctx_institution = request_context&.institution
    @role_limit      = request_context&.role_limit || Role::NO_LIMIT
    @prebuilt_search = prebuilt_search
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
    elsif @ctx_institution != @prebuilt_search.institution
      return WRONG_SCOPE_RESULT
    end
    effective_institution_admin(@user, @ctx_institution, @role_limit)
  end
end
