# frozen_string_literal: true

class LocalIdentityPolicy < ApplicationPolicy

  WRONG_SCOPE_RESULT = {
    authorized: false,
    reason:     "This identity resides in a different institution."
  }

  ##
  # @param request_context [RequestContext]
  # @param identity [LocalIdentity]
  #
  def initialize(request_context, identity)
    @user            = request_context&.user
    @ctx_institution = request_context&.institution
    @role_limit      = request_context&.role_limit || Role::NO_LIMIT
    @identity        = identity
  end

  def create
    effective_sysadmin(@user, @role_limit)
  end

  def edit_password
    user_matches_identity
  end

  def new
    create
  end

  def new_password
    register
  end

  def register
    if @ctx_institution != @identity.user.institution
      return WRONG_SCOPE_RESULT
    end
    AUTHORIZED_RESULT
  end

  def reset_password
    register
  end

  def update
    register
  end

  def update_password
    user_matches_identity
  end


  private

  def user_matches_identity
    if @ctx_institution != @identity.user.institution
      return WRONG_SCOPE_RESULT
    elsif @user && (@role_limit >= Role::LOGGED_IN && @user.id == @identity.user&.id)
      return AUTHORIZED_RESULT
    end
    { authorized: false,
      reason: "Your user account is not associated with this identity." }
  end

end
