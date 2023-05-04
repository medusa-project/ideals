class StatisticPolicy < ApplicationPolicy

  ##
  # @param request_context [RequestContext]
  # @param statistic [Statistic]
  #
  def initialize(request_context, statistic)
    @user       = request_context&.user
    @role_limit = request_context&.role_limit || Role::NO_LIMIT
    @statistic  = statistic
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
