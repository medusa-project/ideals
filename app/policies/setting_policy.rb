class SettingPolicy < ApplicationPolicy
  attr_reader :user, :role, :setting

  ##
  # @param request_context [RequestContext]
  # @param setting [Setting]
  #
  def initialize(request_context, setting)
    @user    = request_context&.user
    @role    = request_context&.role_limit
    @setting = setting
  end

  def index
    effective_sysadmin(user, role)
  end

  def update
    index
  end

end
