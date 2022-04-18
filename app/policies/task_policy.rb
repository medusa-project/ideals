class TaskPolicy < ApplicationPolicy
  attr_reader :user, :role, :task

  ##
  # @param request_context [RequestContext]
  # @param task [Task]
  #
  def initialize(request_context, task)
    @user = request_context&.user
    @role = request_context&.role_limit
    @task = task
  end

  def index
    effective_sysadmin(user, role)
  end

  def show
    index
  end

end
