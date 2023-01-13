class InstitutionPolicy < ApplicationPolicy
  attr_reader :user, :ctx_institution, :role, :institution

  ##
  # @param request_context [RequestContext]
  # @param institution [Institution]
  #
  def initialize(request_context, institution)
    @user            = request_context&.user
    @ctx_institution = request_context&.institution
    @role            = request_context&.role_limit
    @institution     = institution
  end

  def create
    effective_sysadmin(user, role)
  end

  def destroy
    create
  end

  def edit_administrators
    edit_settings
  end

  def edit_preservation
    update_preservation
  end

  def edit_properties
    update_properties
  end

  def edit_settings
    update_settings
  end

  def edit_theme
    edit_settings
  end

  def index
    create
  end

  def invite_administrator
    effective_sysadmin(user, role)
  end

  def item_download_counts
    show_statistics
  end

  def new
    create
  end

  def show
    result = effective_institution_admin(user, ctx_institution, role)
    result[:authorized] ?
      effective_institution_admin(user, institution, role) :
      result
  end

  def show_access
    show
  end

  def show_preservation
    effective_sysadmin(user, role)
  end

  def show_properties
    show
  end

  def show_settings
    show
  end

  def show_statistics
    show
  end

  def show_theme
    show
  end

  def show_users
    show
  end

  def statistics_by_range
    show_statistics
  end

  def update_preservation
    effective_sysadmin(user, role)
  end

  def update_properties
    effective_sysadmin(user, role)
  end

  def update_settings
    show
  end

end
