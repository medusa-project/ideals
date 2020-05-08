# frozen_string_literal: true

class LocalIdentityPolicy < ApplicationPolicy
  attr_reader :user, :role, :identity

  ##
  # @param user_context [UserContext]
  # @param identity [LocalIdentity]
  #
  def initialize(user_context, identity)
    @user     = user_context&.user
    @role     = user_context&.role_limit || Role::NO_LIMIT
    @identity = identity
  end

  def activate?
    true
  end

  def edit_password?
    self?
  end

  def new_password?
    true
  end

  def register?
    true
  end

  def reset_password?
    true
  end

  def update?
    true
  end

  def update_password?
    self?
  end

  private

  def self?
    if user
      return (role >= Role::LOGGED_IN && user.id == identity.user&.id)
    end
    false
  end

end
