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

  def new_password?
    true
  end

  def register?
    true
  end

  def reset_password?
    true
  end

end
