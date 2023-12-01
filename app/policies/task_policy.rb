# frozen_string_literal: true

class TaskPolicy < ApplicationPolicy

  WRONG_SCOPE_RESULT = {
    authorized: false,
    reason:     "This task resides in a different institution."
  }

  ##
  # @param request_context [RequestContext]
  # @param task [Task]
  #
  def initialize(request_context, task)
    super(request_context)
    @task = task
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
    elsif @ctx_institution != @task.institution
      return WRONG_SCOPE_RESULT
    end
    effective_institution_admin(@user, @task.institution, @role_limit)
  end

end
