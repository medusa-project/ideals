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
