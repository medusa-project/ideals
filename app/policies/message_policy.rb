# frozen_string_literal: true

class MessagePolicy < ApplicationPolicy
  attr_reader :user, :role, :message

  ##
  # @param request_context [RequestContext]
  # @param message [Message]
  #
  def initialize(request_context, message)
    @user    = request_context&.user
    @role    = request_context&.role_limit || Role::NO_LIMIT
    @message = message
  end

  def index
    effective_sysadmin(user, role)
  end

end
