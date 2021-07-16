# frozen_string_literal: true

class LocalIdentityPolicy < ApplicationPolicy
  attr_reader :user, :role, :identity

  ##
  # @param request_context [RequestContext]
  # @param identity [LocalIdentity]
  #
  def initialize(request_context, identity)
    @user     = request_context&.user
    @role     = request_context&.role_limit || Role::NO_LIMIT
    @identity = identity
  end

  def activate
    AUTHORIZED_RESULT
  end

  def edit_password
    user_matches_identity
  end

  def new_password
    AUTHORIZED_RESULT
  end

  def register
    AUTHORIZED_RESULT
  end

  def reset_password
    AUTHORIZED_RESULT
  end

  def update
    AUTHORIZED_RESULT
  end

  def update_password
    user_matches_identity
  end


  private

  def user_matches_identity
    if user && (role >= Role::LOGGED_IN && user.id == identity.user&.id)
      return AUTHORIZED_RESULT
    end
    { authorized: false,
      reason: "Your user account is not associated with this identity." }
  end

end
