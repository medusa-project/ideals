# frozen_string_literal: true

class MessagePolicy < ApplicationPolicy

  ##
  # @param request_context [RequestContext]
  # @param message [Message]
  #
  def initialize(request_context, message)
    super(request_context)
    @message = message
  end

  def index
    effective_sysadmin(@user, @role_limit)
  end

  def resend
    show
  end

  def show
    index
  end

end
