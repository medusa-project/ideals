class InstitutionPolicy < ApplicationPolicy

  ##
  # @param request_context [RequestContext]
  # @param institution [Institution]
  #
  def initialize(request_context, institution)
    @user            = request_context&.user
    @ctx_institution = request_context&.institution
    @role_limit      = request_context&.role_limit
    @institution     = institution
  end

  def create
    effective_sysadmin(@user, @role_limit)
  end

  def destroy
    effective_sysadmin(@user, @role_limit)
  end

  def edit_administrators
    edit_settings
  end

  def edit_element_mappings
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
    effective_sysadmin(@user, @role_limit)
  end

  def item_download_counts
    show_statistics
  end

  def new
    effective_sysadmin(@user, @role_limit)
  end

  def show
    effective_institution_admin(@user, @institution, @role_limit)
  end

  def show_access
    show
  end

  def show_element_mappings
    return private_institution unless @institution.public
    show
  end

  def show_preservation
    return private_institution unless @institution.public
    effective_sysadmin(@user, @role_limit)
  end

  def show_properties
    show
  end

  def show_settings
    return private_institution unless @institution.public
    show
  end

  def show_statistics
    return private_institution unless @institution.public
    show
  end

  def show_theme
    return private_institution unless @institution.public
    show
  end

  def show_users
    show
  end

  def statistics_by_range
    show_statistics
  end

  def update_preservation
    update_properties
  end

  def update_properties
    effective_sysadmin(@user, @role_limit)
  end

  def update_settings
    show
  end


  private

  def private_institution
    { authorize: false, reason: "This institution is private." }
  end

end
