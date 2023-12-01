# frozen_string_literal: true

class SettingPolicy < ApplicationPolicy

  ##
  # @param request_context [RequestContext]
  # @param setting [Setting]
  #
  def initialize(request_context, setting)
    super(request_context)
    @setting = setting
  end

  def index
    effective_sysadmin(@user, @role_limit)
  end

  def update
    index
  end

end
