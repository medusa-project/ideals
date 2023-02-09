class ImportPolicy < ApplicationPolicy

  WRONG_SCOPE_RESULT = {
    authorized: false,
    reason:     "This import resides in a different institution."
  }

  ##
  # @param request_context [RequestContext]
  # @param import [Import]
  #
  def initialize(request_context, import)
    @user            = request_context&.user
    @ctx_institution = request_context&.institution
    @role_limit      = request_context&.role_limit
    @import          = import
  end

  def create
    index
  end

  def delete_all_files
    update
  end

  def edit
    update
  end

  def index
    effective_institution_admin(@user, @ctx_institution, @role_limit)
  end

  def new
    create
  end

  def show
    if @ctx_institution != @import.institution
      return WRONG_SCOPE_RESULT
    end
    effective_institution_admin(@user, @import.institution, @role_limit)
  end

  def update
    if @ctx_institution != @import.institution
      return WRONG_SCOPE_RESULT
    elsif @user != @import.user
      return {
        authorized: false,
        reason:     "Imports can only be modified by the user who created them."
      }
    end
    result = create
    return result unless result[:authorized]
    AUTHORIZED_RESULT
  end

  def upload_file
    update
  end

end