class StatisticPolicy < ApplicationPolicy
  attr_reader :user, :role, :statistic

  ##
  # @param request_context [RequestContext]
  # @param statistic [Statistic]
  #
  def initialize(request_context, statistic)
    @user      = request_context&.user
    @role      = request_context&.role_limit
    @statistic = statistic
  end

  def files
    index
  end

  def index
    effective_sysadmin(user, role)
  end

  def items
    index
  end

end
