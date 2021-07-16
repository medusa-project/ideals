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

  def approve
    effective_sysadmin(user, role)
  end

  def create
    effective_sysadmin(user, role)
  end

  def create_unsolicited
    logged_out
  end

  def destroy
    effective_sysadmin(user, role)
  end

  def index
    effective_sysadmin(user, role)
  end

  def new
    logged_out
  end

  def reject
    effective_sysadmin(user, role)
  end

  def resend_email
    effective_sysadmin(user, role)
  end

  def show
    effective_sysadmin(user, role)
  end


  private

  def logged_out
    user.nil? ? AUTHORIZED_RESULT :
      { authorized: false,
        reason: "You cannot perform this action while logged in." }
  end

end
