# frozen_string_literal: true

class InviteePolicy < ApplicationPolicy
  attr_reader :user, :role, :invitee

  ##
  # @param request_context [RequestContext]
  # @param invitee [Invitee]
  #
  def initialize(request_context, invitee)
    @user    = request_context&.user
    @role    = request_context&.role_limit || Role::NO_LIMIT
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
