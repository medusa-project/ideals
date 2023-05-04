class SettingPolicy < ApplicationPolicy

  ##
  # @param request_context [RequestContext]
  # @param setting [Setting]
  #
  def initialize(request_context, setting)
    @user       = request_context&.user
    @role_limit = request_context&.role_limit || Role::NO_LIMIT
    @setting    = setting
  end

  def index
    effective_sysadmin(@user, @role_limit)
  end

  def update
    index
  end

end
