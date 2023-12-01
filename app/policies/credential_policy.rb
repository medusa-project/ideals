# frozen_string_literal: true

class CredentialPolicy < ApplicationPolicy

  WRONG_SCOPE_RESULT = {
    authorized: false,
    reason:     "This credential resides in a different institution."
  }

  ##
  # @param request_context [RequestContext]
  # @param credential [Credential]
  #
  def initialize(request_context, credential)
    super(request_context)
    @credential = credential
  end

  def create
    effective_sysadmin(@user, @role_limit)
  end

  def edit_password
    user_matches_credential
  end

  def new
    create
  end

  def new_password
    register
  end

  def register
    if @ctx_institution != @credential.user.institution
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
    user_matches_credential
  end


  private

  def user_matches_credential
    if @ctx_institution != @credential.user.institution
      return WRONG_SCOPE_RESULT
    elsif @user && (@role_limit >= Role::LOGGED_IN && @user.id == @credential.user&.id)
      return AUTHORIZED_RESULT
    end
    { authorized: false,
      reason: "Your user account is not associated with this credential." }
  end

end
