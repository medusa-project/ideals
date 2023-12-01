# frozen_string_literal: true

class EventPolicy < ApplicationPolicy

  WRONG_SCOPE_RESULT = {
    authorized: false,
    reason:     "This event resides in a different institution."
  }

  ##
  # @param request_context [RequestContext]
  # @param event [Event]
  #
  def initialize(request_context, event)
    super(request_context)
    @event = event
  end

  def index
    effective_institution_admin(@user, @ctx_institution, @role_limit)
  end

  def index_all
    effective_sysadmin(@user, @role_limit)
  end

  def show
    if effective_sysadmin?(@user, @role_limit)
      return AUTHORIZED_RESULT
    elsif @ctx_institution != @event.institution
      return WRONG_SCOPE_RESULT
    end
    effective_institution_admin(@user, @event.institution, @role_limit)
  end

end
