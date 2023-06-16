class UsagePolicy < ApplicationPolicy

  ##
  # @param request_context [RequestContext]
  # @param usage [Usage]
  #
  def initialize(request_context, usage)
    @user       = request_context&.user
    @role_limit = request_context&.role_limit || Role::NO_LIMIT
    @usage      = usage
  end

  def files
    index
  end

  def index
    effective_sysadmin(@user, @role_limit)
  end

  def items
    index
  end

end
