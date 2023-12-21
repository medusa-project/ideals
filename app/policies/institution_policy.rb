# frozen_string_literal: true

class InstitutionPolicy < ApplicationPolicy

  ##
  # @param request_context [RequestContext]
  # @param institution [Institution]
  #
  def initialize(request_context, institution)
    super(request_context)
    @institution = institution
  end

  def create
    effective_sysadmin(@user, @role_limit)
  end

  def destroy
    effective_sysadmin(@user, @role_limit)
  end

  def edit_administering_groups
    edit_settings
  end

  def edit_administering_users
    edit_administering_groups
  end

  def edit_deposit_agreement
    edit_settings
  end

  def edit_deposit_help
    edit_deposit_agreement
  end

  def edit_deposit_questions
    edit_deposit_agreement
  end

  def edit_element_mappings
    edit_settings
  end

  def edit_local_authentication
    edit_settings
  end

  def edit_preservation
    update_preservation
  end

  def edit_properties
    update_properties
  end

  def edit_saml_authentication
    edit_local_authentication
  end

  def edit_settings
    update_settings
  end

  def edit_shibboleth_authentication
    edit_local_authentication
  end

  def edit_theme
    edit_settings
  end

  def generate_saml_cert
    generate_saml_key
  end

  def generate_saml_key
    edit_saml_authentication
  end

  def index
    create
  end

  def item_download_counts
    show_statistics
  end

  def new
    effective_sysadmin(@user, @role_limit)
  end

  def refresh_saml_config_metadata
    edit_saml_authentication
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
    # This is a hack for UIUC only that prevents non-UIUC sysadmins from
    # accessing it, requested here:
    # https://github.com/medusa-project/ideals-issues/issues/107
    # A different approach could be to add another access level beyond
    # sysadmin, like super admin, and make us at UIUC super admins while CARLI
    # remains sysadmins, and make UIUC super admin-only.
    if @institution.key == "uiuc" && @user.institution.key != "uiuc"
      return {
        authorized: false,
        reason:     "Only UIUC administrators are allowed to access this " +
                    "institution."
      }
    end
    effective_institution_admin(@user, @institution, @role_limit)
  end

  def show_access
    show
  end

  def show_authentication
    show_settings
  end

  def show_buried_items
    show
  end

  def show_depositing
    show
  end

  def show_element_mappings
    show
  end

  def show_element_namespaces
    show_metadata_profiles
  end

  def show_element_registry
    show_metadata_profiles
  end

  def show_imports
    show_metadata_profiles
  end

  def show_index_pages
    show_metadata_profiles
  end

  def show_invitees
    show
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

  def show_review_submissions
    show_submissions_in_progress
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

  def show_submissions_in_progress
    show
  end

  def show_theme
    show
  end

  def show_units
    effective_sysadmin(@user, @role_limit)
  end

  def show_usage
    show
  end

  def show_user_groups
    show
  end

  def show_users
    show
  end

  def show_vocabularies
    show_metadata_profiles
  end

  def show_withdrawn_items
    show
  end

  def statistics_by_range
    show_statistics
  end

  def supply_saml_configuration
    edit_saml_authentication
  end

  def update_deposit_agreement_questions
    update_settings
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
