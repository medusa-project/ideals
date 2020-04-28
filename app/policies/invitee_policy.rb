# frozen_string_literal: true

class InviteePolicy < ApplicationPolicy
  attr_reader :user, :role, :invitee

  ##
  # @param user_context [UserContext]
  # @param invitee [Invitee]
  #
  def initialize(user_context, invitee)
    @user    = user_context&.user
    @role    = user_context&.role_limit || Role::NO_LIMIT
    @invitee = invitee
  end

  def create?
    user&.sysadmin? && role >= Role::SYSTEM_ADMINISTRATOR
  end

  def destroy?
    create?
  end

  def index?
    update?
  end

  def new?
    true
  end

  def update?
    create?
  end
end
