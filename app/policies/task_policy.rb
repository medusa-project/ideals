class TaskPolicy < ApplicationPolicy

  attr_reader :user, :ctx_institution, :role, :task

  ##
  # @param request_context [RequestContext]
  # @param task [Task]
  #
  def initialize(request_context, task)
    @user            = request_context&.user
    @ctx_institution = request_context&.institution
    @role            = request_context&.role_limit
    @task            = task
  end

  def index
    effective_institution_admin(user, ctx_institution, role)
  end

  def index_all
    effective_sysadmin(user, role)
  end

  def show
    result = effective_institution_admin(user, ctx_institution, role)
    result[:authorized] ?
      effective_institution_admin(user, task.institution, role) :
      result
  end

end
