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

  def approve?
    sysadmin?
  end

  def create?
    sysadmin?
  end

  def create_unsolicited?
    user.nil?
  end

  def destroy?
    sysadmin?
  end

  def index?
    sysadmin?
  end

  def new?
    user.nil?
  end

  def reject?
    sysadmin?
  end

  def resend_email?
    sysadmin?
  end

  def show?
    sysadmin?
  end

  private

  def sysadmin?
    user&.sysadmin? && role >= Role::SYSTEM_ADMINISTRATOR
  end

end
