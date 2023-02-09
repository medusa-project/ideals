# frozen_string_literal: true

class FileFormatPolicy < ApplicationPolicy

  ##
  # @param request_context [RequestContext]
  # @param file_format [FileFormat]
  #
  def initialize(request_context, file_format)
    @user        = request_context&.user
    @role_limit  = request_context&.role_limit || Role::NO_LIMIT
    @file_format = file_format
  end

  def index
    effective_sysadmin(@user, @role_limit)
  end

end
