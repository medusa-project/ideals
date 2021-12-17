# frozen_string_literal: true

class ImportPolicy < ApplicationPolicy
  attr_reader :user, :role, :import

  ##
  # @param request_context [RequestContext]
  # @param import [Import]
  #
  def initialize(request_context, import)
    @user   = request_context&.user
    @role   = request_context&.role_limit
    @import = import
  end

  def create
    effective_sysadmin(user, role)
  end

  def delete_all_files
    update
  end

  def edit
    update
  end

  def index
    effective_sysadmin(user, role)
  end

  def new
    create
  end

  def show
    index
  end

  def update
    result = create
    return result unless result[:authorized]
    if user != import.user
      return {
        authorized: false,
        reason:     "Imports can only be modified by the user who created them."
      }
    end
    AUTHORIZED_RESULT
  end

  def upload_file
    update
  end

end