class ImportPolicy < ApplicationPolicy

  attr_reader :user, :institution, :role, :import

  ##
  # @param request_context [RequestContext]
  # @param import [Import]
  #
  def initialize(request_context, import)
    @user        = request_context&.user
    @institution = request_context&.institution
    @role        = request_context&.role_limit
    @import      = import
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
    effective_institution_admin(user, institution, role)
  end

  def new
    create
  end

  def show
    effective_institution_admin(user, import.institution, role)
  end

  def update
    if user != import.user
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