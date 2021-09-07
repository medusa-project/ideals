# frozen_string_literal: true

class FileFormatPolicy < ApplicationPolicy
  attr_reader :user, :role, :file_format

  ##
  # @param request_context [RequestContext]
  # @param file_format [FileFormat]
  #
  def initialize(request_context, file_format)
    @user    = request_context&.user
    @role    = request_context&.role_limit || Role::NO_LIMIT
    @file_format = file_format
  end

  def index
    effective_sysadmin(user, role)
  end

end
