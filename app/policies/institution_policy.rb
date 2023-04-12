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

  def remove_banner_image
    update_settings
  end

  def remove_favicon
    update_settings
  end

  def remove_footer_image
    update_settings
  end

  def remove_header_image
    update_settings
  end

  def show
    effective_institution_admin(@user, @institution, @role_limit)
  end

  def show_access
    show
  end

  def show_element_mappings
    show
  end

  def show_element_registry
    show_metadata_profiles
  end

  def show_index_pages
    show_metadata_profiles
  end

  def show_metadata_profiles
    effective_sysadmin(@user, @role_limit)
  end

  def show_prebuilt_searches
    show_metadata_profiles
  end

  def show_preservation
    effective_sysadmin(@user, @role_limit)
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

  def show_submission_profiles
    show_metadata_profiles
  end

  def show_theme
    show
  end

  def show_units
    effective_sysadmin(@user, @role_limit)
  end

  def show_users
    show
  end

  def show_vocabularies
    show_metadata_profiles
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

end
