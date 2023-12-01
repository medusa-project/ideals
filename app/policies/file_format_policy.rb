# frozen_string_literal: true

class FileFormatPolicy < ApplicationPolicy

  ##
  # @param request_context [RequestContext]
  # @param file_format [FileFormat]
  #
  def initialize(request_context, file_format)
    super(request_context)
    @file_format = file_format
  end

  def index
    effective_sysadmin(@user, @role_limit)
  end

end
