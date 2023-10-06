class ImportPolicy < ApplicationPolicy

  WRONG_SCOPE_RESULT = {
    authorized: false,
    reason:     "This import resides in a different institution."
  }

  ##
  # @param request_context [RequestContext]
  # @param import [Import]
  #
  def initialize(request_context, import)
    @user            = request_context&.user
    @ctx_institution = request_context&.institution
    @role_limit      = request_context&.role_limit || Role::NO_LIMIT
    @import          = import
  end

  def complete_upload
    update
  end

  def create
    index
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
    if !@user
      return LOGGED_OUT_RESULT
    elsif effective_sysadmin?(@user, @role_limit)
      return AUTHORIZED_RESULT
    elsif @ctx_institution != @import.institution
      return WRONG_SCOPE_RESULT
    end
    effective_institution_admin(@user, @import.institution, @role_limit)
  end

  def update
    if !@user
      return LOGGED_OUT_RESULT
    elsif effective_sysadmin?(@user, @role_limit)
      return AUTHORIZED_RESULT
    elsif @ctx_institution != @import.institution
      return WRONG_SCOPE_RESULT
    elsif @user != @import.user
      return {
        authorized: false,
        reason:     "Imports can only be modified by the user who created them."
      }
    end
    result = create
    return result unless result[:authorized]
    AUTHORIZED_RESULT
  end

end