# frozen_string_literal: true

class UsagePolicy < ApplicationPolicy

  ##
  # @param request_context [RequestContext]
  # @param usage [Usage]
  #
  def initialize(request_context, usage)
    super(request_context)
    @usage = usage
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
