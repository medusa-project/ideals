require 'test_helper'

class InstitutionsControllerTest < ActionDispatch::IntegrationTest

  setup do
    @institution = institutions(:southwest)
    host! @institution.fqdn
    setup_opensearch
  end

  teardown do
    log_out
  end

  # create()

  test "create() returns HTTP 404 for unscoped requests" do
    host! ::Configuration.instance.main_host
    post institutions_path
    assert_response :not_found
  end

  test "create() redirects to root page for logged-out users" do
    post institutions_path
    assert_redirected_to @institution.scope_url
  end

  test "create() returns HTTP 403 for unauthorized users" do
    log_in_as(users(:southwest))
    post institutions_path,
         xhr: true,
         params: {
           institution: {
             name: "New Institution",
             key:  "new",
             fqdn: "new.org"
           }
         }
    assert_response :forbidden
  end

  test "create() returns HTTP 200 for sysadmins" do
    log_in_as(users(:southwest_sysadmin))
    post institutions_path,
         xhr: true,
         params: {
           institution: {
             name:             "New Institution",
             service_name:     "New",
             key:              "new",
             fqdn:             "new.org",
             main_website_url: "https://new.org"
           }
         }
    assert_response :ok
  end

  test "create() creates an institution" do
    user = users(:southwest_sysadmin)
    log_in_as(user)
    assert_difference "Institution.count" do
      post institutions_path,
           xhr: true,
           params: {
             institution: {
               name:             "New Institution",
               service_name:     "New",
               key:              "new",
               fqdn:             "new.org",
               main_website_url: "https://new.org"
             }
           }
    end
  end

  test "create() returns HTTP 400 for illegal arguments" do
    log_in_as(users(:southwest_sysadmin))
    post institutions_path,
         xhr: true,
         params: {
           institution: {
             name: ""
           }
         }
    assert_response :bad_request
  end

  # destroy()

  test "destroy() returns HTTP 404 for unscoped requests" do
    host! ::Configuration.instance.main_host
    delete institution_path(@institution)
    assert_response :not_found
  end

  test "destroy() redirects to root page for logged-out users" do
    delete institution_path(@institution)
    assert_redirected_to @institution.scope_url
  end

  test "destroy() returns HTTP 403 for unauthorized users" do
    log_in_as(users(:southwest))
    delete institution_path(@institution)
    assert_response :forbidden
  end

  test "destroy() destroys the institution" do
    setup_s3
    log_in_as(users(:southwest_sysadmin))
    @institution.nuke!
    delete institution_path(@institution)
    assert_raises ActiveRecord::RecordNotFound do
      @institution.reload
    end
  end

  test "destroy() returns HTTP 302 for an existing institution" do
    log_in_as(users(:southwest_sysadmin))
    delete institution_path(@institution)
    assert_redirected_to institutions_path
  end

  test "destroy() returns HTTP 404 for a missing institution" do
    log_in_as(users(:southwest_sysadmin))
    delete "/institutions/bogus"
    assert_response :not_found
  end

  # edit_administering_groups()

  test "edit_administering_groups() returns HTTP 404 for unscoped requests" do
    host! ::Configuration.instance.main_host
    delete institution_edit_administering_groups_path(@institution)
    assert_response :not_found
  end

  test "edit_administering_groups() returns HTTP 403 for logged-out users" do
    get institution_edit_administering_groups_path(@institution), xhr: true
    assert_response :forbidden
  end

  test "edit_administering_groups() returns HTTP 403 for unauthorized users" do
    log_in_as(users(:southwest))
    get institution_edit_administering_groups_path(@institution), xhr: true
    assert_response :forbidden
  end

  test "edit_administering_groups() returns HTTP 404 for non-XHR requests" do
    log_in_as(users(:southwest_admin))
    get institution_edit_administering_groups_path(@institution)
    assert_response :not_found
  end

  test "edit_administering_groups() returns HTTP 200 for XHR requests" do
    log_in_as(users(:southwest_admin))
    get institution_edit_administering_groups_path(@institution), xhr: true
    assert_response :ok
  end

  # edit_administering_users()

  test "edit_administering_users() returns HTTP 404 for unscoped requests" do
    host! ::Configuration.instance.main_host
    delete institution_edit_administering_users_path(@institution)
    assert_response :not_found
  end

  test "edit_administering_users() returns HTTP 403 for logged-out users" do
    get institution_edit_administering_users_path(@institution), xhr: true
    assert_response :forbidden
  end

  test "edit_administering_users() returns HTTP 403 for unauthorized users" do
    log_in_as(users(:southwest))
    get institution_edit_administering_users_path(@institution), xhr: true
    assert_response :forbidden
  end

  test "edit_administering_users() returns HTTP 404 for non-XHR requests" do
    log_in_as(users(:southwest_admin))
    get institution_edit_administering_users_path(@institution)
    assert_response :not_found
  end

  test "edit_administering_users() returns HTTP 200 for XHR requests" do
    log_in_as(users(:southwest_admin))
    get institution_edit_administering_users_path(@institution), xhr: true
    assert_response :ok
  end

  # edit_deposit_agreement()

  test "edit_deposit_agreement() returns HTTP 404 for unscoped requests" do
    host! ::Configuration.instance.main_host
    get institution_edit_deposit_agreement_path(@institution), xhr: true
    assert_response :not_found
  end

  test "edit_deposit_agreement() returns HTTP 403 for logged-out users" do
    get institution_edit_deposit_agreement_path(@institution), xhr: true
    assert_response :forbidden
  end

  test "edit_deposit_agreement() returns HTTP 403 for unauthorized users" do
    log_in_as(users(:southwest))
    get institution_edit_deposit_agreement_path(@institution), xhr: true
    assert_response :forbidden
  end

  test "edit_deposit_agreement() returns HTTP 200" do
    log_in_as(users(:southwest_admin))
    get institution_edit_deposit_agreement_path(@institution), xhr: true
    assert_response :ok
  end

  # edit_deposit_help()

  test "edit_deposit_help() returns HTTP 404 for unscoped requests" do
    host! ::Configuration.instance.main_host
    get institution_edit_deposit_help_path(@institution), xhr: true
    assert_response :not_found
  end

  test "edit_deposit_help() returns HTTP 403 for logged-out users" do
    get institution_edit_deposit_help_path(@institution), xhr: true
    assert_response :forbidden
  end

  test "edit_deposit_help() returns HTTP 403 for unauthorized users" do
    log_in_as(users(:southwest))
    get institution_edit_deposit_help_path(@institution), xhr: true
    assert_response :forbidden
  end

  test "edit_deposit_help() returns HTTP 200" do
    log_in_as(users(:southwest_admin))
    get institution_edit_deposit_help_path(@institution), xhr: true
    assert_response :ok
  end

  # edit_deposit_questions()

  test "edit_deposit_questions() returns HTTP 404 for unscoped requests" do
    host! ::Configuration.instance.main_host
    get institution_edit_deposit_questions_path(@institution), xhr: true
    assert_response :not_found
  end

  test "edit_deposit_questions() returns HTTP 403 for logged-out users" do
    get institution_edit_deposit_questions_path(@institution), xhr: true
    assert_response :forbidden
  end

  test "edit_deposit_questions() returns HTTP 403 for unauthorized users" do
    log_in_as(users(:southwest))
    get institution_edit_deposit_questions_path(@institution), xhr: true
    assert_response :forbidden
  end

  test "edit_deposit_questions() returns HTTP 200" do
    log_in_as(users(:southwest_admin))
    get institution_edit_deposit_questions_path(@institution), xhr: true
    assert_response :ok
  end

  # edit_element_mappings()

  test "edit_element_mappings() returns HTTP 404 for unscoped requests" do
    host! ::Configuration.instance.main_host
    get institution_element_mappings_edit_path(@institution), xhr: true
    assert_response :not_found
  end

  test "edit_element_mappings() returns HTTP 403 for logged-out users" do
    get institution_element_mappings_edit_path(@institution), xhr: true
    assert_response :forbidden
  end

  test "edit_element_mappings() returns HTTP 403 for unauthorized users" do
    log_in_as(users(:southwest))
    get institution_element_mappings_edit_path(@institution), xhr: true
    assert_response :forbidden
  end

  test "edit_element_mappings() returns HTTP 200" do
    log_in_as(users(:southwest_admin))
    get institution_element_mappings_edit_path(@institution), xhr: true
    assert_response :ok
  end

  # edit_local_authentication()

  test "edit_local_authentication() returns HTTP 404 for unscoped requests" do
    host! ::Configuration.instance.main_host
    get institution_edit_local_authentication_path(@institution), xhr: true
    assert_response :not_found
  end

  test "edit_local_authentication() returns HTTP 403 for logged-out users" do
    get institution_edit_local_authentication_path(@institution), xhr: true
    assert_response :forbidden
  end

  test "edit_local_authentication() returns HTTP 403 for unauthorized users" do
    log_in_as(users(:southwest))
    get institution_edit_local_authentication_path(@institution), xhr: true
    assert_response :forbidden
  end

  test "edit_local_authentication() returns HTTP 200" do
    log_in_as(users(:southwest_admin))
    get institution_edit_local_authentication_path(@institution), xhr: true
    assert_response :ok
  end

  # edit_preservation()

  test "edit_preservation() returns HTTP 404 for unscoped requests" do
    host! ::Configuration.instance.main_host
    get institution_edit_preservation_path(@institution), xhr: true
    assert_response :not_found
  end

  test "edit_preservation() returns HTTP 403 for logged-out users" do
    get institution_edit_preservation_path(@institution), xhr: true
    assert_response :forbidden
  end

  test "edit_preservation() returns HTTP 403 for unauthorized users" do
    log_in_as(users(:southwest))
    get institution_edit_preservation_path(@institution), xhr: true
    assert_response :forbidden
  end

  test "edit_preservation() returns HTTP 200" do
    log_in_as(users(:southwest_sysadmin))
    get institution_edit_preservation_path(@institution), xhr: true
    assert_response :ok
  end

  # edit_properties()

  test "edit_properties() returns HTTP 404 for unscoped requests" do
    host! ::Configuration.instance.main_host
    get institution_edit_properties_path(@institution), xhr: true
    assert_response :not_found
  end

  test "edit_properties() returns HTTP 403 for logged-out users" do
    get institution_edit_properties_path(@institution), xhr: true
    assert_response :forbidden
  end

  test "edit_properties() returns HTTP 403 for unauthorized users" do
    log_in_as(users(:southwest))
    get institution_edit_properties_path(@institution), xhr: true
    assert_response :forbidden
  end

  test "edit_properties() returns HTTP 200" do
    log_in_as(users(:southwest_sysadmin))
    get institution_edit_properties_path(@institution), xhr: true
    assert_response :ok
  end

  # edit_saml_authentication()

  test "edit_saml_authentication() returns HTTP 404 for unscoped requests" do
    host! ::Configuration.instance.main_host
    get institution_edit_saml_authentication_path(@institution), xhr: true
    assert_response :not_found
  end

  test "edit_saml_authentication() returns HTTP 403 for logged-out users" do
    get institution_edit_saml_authentication_path(@institution), xhr: true
    assert_response :forbidden
  end

  test "edit_saml_authentication() returns HTTP 403 for unauthorized users" do
    log_in_as(users(:southwest))
    get institution_edit_saml_authentication_path(@institution), xhr: true
    assert_response :forbidden
  end

  test "edit_saml_authentication() returns HTTP 200" do
    log_in_as(users(:southwest_admin))
    get institution_edit_saml_authentication_path(@institution), xhr: true
    assert_response :ok
  end

  # edit_settings()

  test "edit_settings() returns HTTP 404 for unscoped requests" do
    host! ::Configuration.instance.main_host
    get institution_edit_settings_path(@institution), xhr: true
    assert_response :not_found
  end

  test "edit_settings() returns HTTP 403 for logged-out users" do
    get institution_edit_settings_path(@institution), xhr: true
    assert_response :forbidden
  end

  test "edit_settings() returns HTTP 403 for unauthorized users" do
    log_in_as(users(:southwest))
    get institution_edit_settings_path(@institution), xhr: true
    assert_response :forbidden
  end

  test "edit_settings() returns HTTP 200" do
    log_in_as(users(:southwest_admin))
    get institution_edit_settings_path(@institution), xhr: true
    assert_response :ok
  end

  # edit_theme()

  test "edit_theme() returns HTTP 404 for unscoped requests" do
    host! ::Configuration.instance.main_host
    get institution_edit_theme_path(@institution), xhr: true
    assert_response :not_found
  end

  test "edit_theme() returns HTTP 403 for logged-out users" do
    get institution_edit_theme_path(@institution), xhr: true
    assert_response :forbidden
  end

  test "edit_theme() returns HTTP 403 for unauthorized users" do
    log_in_as(users(:southwest))
    get institution_edit_theme_path(@institution), xhr: true
    assert_response :forbidden
  end

  test "edit_theme() returns HTTP 404 for non-XHR requests" do
    log_in_as(users(:southwest_admin))
    get institution_edit_theme_path(@institution)
    assert_response :not_found
  end

  test "edit_theme() returns HTTP 200 for XHR requests" do
    log_in_as(users(:southwest_admin))
    get institution_edit_theme_path(@institution), xhr: true
    assert_response :ok
  end

  # generate_saml_cert()

  test "generate_saml_cert() returns HTTP 404 for unscoped requests" do
    host! ::Configuration.instance.main_host
    patch institution_generate_saml_cert_path(@institution)
    assert_response :not_found
  end

  test "generate_saml_cert() redirects to root page for logged-out users" do
    patch institution_generate_saml_cert_path(@institution)
    assert_redirected_to @institution.scope_url
  end

  test "generate_saml_cert() returns HTTP 403 for unauthorized users" do
    log_in_as(users(:southwest))
    patch institution_generate_saml_cert_path(@institution)
    assert_response :forbidden
  end

  test "generate_saml_cert() does not update an institution's certs when the
  institution does not have a private key set" do
    user = users(:southwest_admin)
    log_in_as(user)
    institution = user.institution
    institution.update!(saml_sp_private_key: nil,
                        saml_sp_public_cert: nil)
    patch institution_generate_saml_cert_path(institution)
    institution.reload
    assert_nil institution.saml_sp_public_cert
  end

  test "generate_saml_cert() updates an institution's SAML cert" do
    user = users(:southwest_admin)
    log_in_as(user)
    institution = user.institution
    institution.update!(saml_sp_private_key: CryptUtils.generate_key.private_to_pem,
                        saml_sp_public_cert: nil)
    patch institution_generate_saml_cert_path(institution)
    institution.reload
    assert_not_empty institution.saml_sp_public_cert
  end

  test "generate_saml_cert() nils out an institution's next SAML cert" do
    user = users(:southwest_admin)
    log_in_as(user)
    institution = user.institution
    institution.update!(saml_sp_private_key:      CryptUtils.generate_key.private_to_pem,
                        saml_sp_public_cert:      nil,
                        saml_sp_next_public_cert: "something")
    patch institution_generate_saml_cert_path(institution)
    institution.reload
    assert_nil institution.saml_sp_next_public_cert
  end

  test "generate_saml_cert() returns HTTP 302" do
    user = users(:southwest_admin)
    log_in_as(user)
    institution = user.institution
    patch institution_generate_saml_cert_path(institution)
    assert_redirected_to institution_path(institution)
  end

  test "generate_saml_cert() returns HTTP 404 for nonexistent
  institutions" do
    log_in_as(users(:southwest_admin))
    patch "/institutions/bogus/generate-saml-cert"
    assert_response :not_found
  end

  # generate_saml_key()

  test "generate_saml_key() returns HTTP 404 for unscoped requests" do
    host! ::Configuration.instance.main_host
    patch institution_generate_saml_key_path(@institution)
    assert_response :not_found
  end

  test "generate_saml_key() redirects to root page for logged-out users" do
    patch institution_generate_saml_key_path(@institution)
    assert_redirected_to @institution.scope_url
  end

  test "generate_saml_key() returns HTTP 403 for unauthorized users" do
    log_in_as(users(:southwest))
    patch institution_generate_saml_key_path(@institution)
    assert_response :forbidden
  end

  test "generate_saml_key() updates an institution's SAML private key" do
    user = users(:southwest_admin)
    log_in_as(user)
    institution = user.institution
    patch institution_generate_saml_key_path(institution)
    institution.reload
    assert_not_empty institution.saml_sp_private_key
  end

  test "generate_saml_key() returns HTTP 302" do
    user = users(:southwest_admin)
    log_in_as(user)
    institution = user.institution
    patch institution_generate_saml_key_path(institution)
    assert_redirected_to institution_path(institution)
  end

  test "generate_saml_key() returns HTTP 404 for nonexistent
  institutions" do
    log_in_as(users(:southwest_admin))
    patch "/institutions/bogus/generate-saml-key"
    assert_response :not_found
  end

  # index()

  test "index() returns HTTP 404 for unscoped requests" do
    host! ::Configuration.instance.main_host
    get institutions_path
    assert_response :not_found
  end

  test "index() redirects to root page for logged-out users" do
    get institutions_path
    assert_redirected_to @institution.scope_url
  end

  test "index() returns HTTP 403 for unauthorized users" do
    log_in_as(users(:southwest))
    get institutions_path
    assert_response :forbidden
  end

  test "index() returns HTTP 200 for sysadmins" do
    log_in_as(users(:southwest_sysadmin))
    get institutions_path
    assert_response :ok
  end

  # item_download_counts()

  test "item_download_counts() returns HTTP 404 for unscoped requests" do
    host! ::Configuration.instance.main_host
    get institution_item_download_counts_path(@institution)
    assert_response :not_found
  end

  test "item_download_counts() redirects to root page for logged-out users" do
    get institution_item_download_counts_path(@institution)
    assert_redirected_to @institution.scope_url
  end

  test "item_download_counts() returns HTTP 403 for unauthorized users" do
    log_in_as(users(:southwest))
    get institution_item_download_counts_path(@institution)
    assert_response :forbidden
  end

  test "item_download_counts() returns HTTP 200" do
    log_in_as(users(:southwest_admin))
    get institution_item_download_counts_path(@institution)
    assert_response :ok
  end

  # new()

  test "new() returns HTTP 404 for unscoped requests" do
    host! ::Configuration.instance.main_host
    get new_institution_path
    assert_response :not_found
  end

  test "new() redirects to root page for logged-out users" do
    get new_institution_path
    assert_redirected_to @institution.scope_url
  end

  test "new() returns HTTP 403 for unauthorized users" do
    log_in_as(users(:southwest))
    get new_institution_path
    assert_response :forbidden
  end

  test "new() returns HTTP 200 for authorized users" do
    log_in_as(users(:southwest_sysadmin))
    get new_institution_path
    assert_response :ok
  end

  # refresh_saml_config_metadata()

  test "refresh_saml_config_metadata() returns HTTP 404 for unscoped requests" do
    host! ::Configuration.instance.main_host
    patch institution_refresh_saml_config_metadata_path(@institution)
    assert_response :not_found
  end

  test "refresh_saml_config_metadata() redirects to root page for logged-out
  users" do
    patch institution_refresh_saml_config_metadata_path(@institution)
    assert_redirected_to @institution.scope_url
  end

  test "refresh_saml_config_metadata() returns HTTP 403 for unauthorized users" do
    log_in_as(users(:southwest))
    patch institution_refresh_saml_config_metadata_path(@institution)
    assert_response :forbidden
  end

  test "refresh_saml_config_metadata() updates an institution's SAML metadata" do
    skip # TODO: why isn't the job executing in the test environment?
    user = users(:southwest_admin)
    log_in_as(user)
    institution = user.institution
    patch institution_refresh_saml_config_metadata_path(institution)
    institution.reload
    assert_not_nil institution.saml_idp_signing_cert
  end

  test "refresh_saml_config_metadata() returns HTTP 302" do
    user = users(:southwest_admin)
    log_in_as(user)
    institution = user.institution
    patch institution_refresh_saml_config_metadata_path(institution)
    assert_redirected_to institution_path(institution)
  end

  test "refresh_saml_config_metadata() returns HTTP 404 for nonexistent
  institutions" do
    log_in_as(users(:southwest_admin))
    patch "/institutions/bogus/refresh-saml-config-metadata"
    assert_response :not_found
  end

  # remove_banner_image()

  test "remove_banner_image() returns HTTP 404 for unscoped requests" do
    host! ::Configuration.instance.main_host
    delete institution_banner_image_path(@institution)
    assert_response :not_found
  end

  test "remove_banner_image() redirects to root page for logged-out users" do
    delete institution_banner_image_path(@institution)
    assert_redirected_to @institution.scope_url
  end

  test "remove_banner_image() returns HTTP 403 for unauthorized users" do
    log_in_as(users(:southwest))
    delete institution_banner_image_path(@institution)
    assert_response :forbidden
  end

  test "remove_banner_image() removes an institution's banner image" do
    user = users(:southwest_admin)
    log_in_as(user)
    institution = user.institution
    delete institution_banner_image_path(institution)
    institution.reload
    assert_nil institution.banner_image_filename
  end

  test "remove_banner_image() redirects back to the institution page" do
    user = users(:southwest_admin)
    log_in_as(user)
    delete institution_banner_image_path(user.institution)
    assert_redirected_to user.institution
  end

  test "remove_banner_image() returns HTTP 404 for a nonexistent institution" do
    log_in_as(users(:southwest_admin))
    delete "/institutions/bogus/banner-image"
    assert_response :not_found
  end

  # remove_favicon()

  test "remove_favicon() returns HTTP 404 for unscoped requests" do
    host! ::Configuration.instance.main_host
    delete institution_favicon_path(@institution)
    assert_response :not_found
  end

  test "remove_favicon() redirects to root page for logged-out users" do
    delete institution_favicon_path(@institution)
    assert_redirected_to @institution.scope_url
  end

  test "remove_favicon() returns HTTP 403 for unauthorized users" do
    log_in_as(users(:southwest))
    delete institution_favicon_path(@institution)
    assert_response :forbidden
  end

  test "remove_favicon() removes an institution's favicon" do
    user = users(:southwest_admin)
    log_in_as(user)
    institution = user.institution
    delete institution_favicon_path(institution)
    institution.reload
    assert !institution.has_favicon
  end

  test "remove_favicon() redirects back to the institution page" do
    user = users(:southwest_admin)
    log_in_as(user)
    delete institution_favicon_path(user.institution)
    assert_redirected_to user.institution
  end

  test "remove_favicon() returns HTTP 404 for a nonexistent institution" do
    log_in_as(users(:southwest_admin))
    delete "/institutions/bogus/favicon"
    assert_response :not_found
  end

  # remove_footer_image()

  test "remove_footer_image() returns HTTP 404 for unscoped requests" do
    host! ::Configuration.instance.main_host
    delete institution_footer_image_path(@institution)
    assert_response :not_found
  end

  test "remove_footer_image() redirects to root page for logged-out users" do
    delete institution_footer_image_path(@institution)
    assert_redirected_to @institution.scope_url
  end

  test "remove_footer_image() returns HTTP 403 for unauthorized users" do
    log_in_as(users(:southwest))
    delete institution_footer_image_path(@institution)
    assert_response :forbidden
  end

  test "remove_footer_image() removes an institution's banner image" do
    user = users(:southwest_admin)
    log_in_as(user)
    institution = user.institution
    delete institution_footer_image_path(institution)
    institution.reload
    assert_nil institution.banner_image_filename
  end

  test "remove_footer_image() redirects back to the institution page" do
    user = users(:southwest_admin)
    log_in_as(user)
    delete institution_footer_image_path(user.institution)
    assert_redirected_to user.institution
  end

  test "remove_footer_image() returns HTTP 404 for a nonexistent institution" do
    log_in_as(users(:southwest_admin))
    delete "/institutions/bogus/footer-image"
    assert_response :not_found
  end

  # remove_header_image()

  test "remove_header_image() returns HTTP 404 for unscoped requests" do
    host! ::Configuration.instance.main_host
    delete institution_header_image_path(@institution)
    assert_response :not_found
  end

  test "remove_header_image() redirects to root page for logged-out users" do
    delete institution_header_image_path(@institution)
    assert_redirected_to @institution.scope_url
  end

  test "remove_header_image() returns HTTP 403 for unauthorized users" do
    log_in_as(users(:southwest))
    delete institution_header_image_path(@institution)
    assert_response :forbidden
  end

  test "remove_header_image() removes an institution's banner image" do
    user = users(:southwest_admin)
    log_in_as(user)
    institution = user.institution
    delete institution_header_image_path(institution)
    institution.reload
    assert_nil institution.header_image_filename
  end

  test "remove_header_image() redirects back to the institution page" do
    user = users(:southwest_admin)
    log_in_as(user)
    delete institution_header_image_path(user.institution)
    assert_redirected_to user.institution
  end

  test "remove_header_image() returns HTTP 404 for a nonexistent institution" do
    log_in_as(users(:southwest_admin))
    delete "/institutions/bogus/header-image"
    assert_response :not_found
  end

  # show()

  test "show() returns HTTP 404 for unscoped requests" do
    host! ::Configuration.instance.main_host
    get institution_path(@institution)
    assert_response :not_found
  end

  test "show() redirects to root page for logged-out users" do
    get institution_path(@institution)
    assert_redirected_to @institution.scope_url
  end

  test "show() returns HTTP 403 for non-administrators of the same institution" do
    log_in_as(users(:southwest))
    get institution_path(@institution)
    assert_response :forbidden
  end

  test "show() returns HTTP 403 for users of a different institution" do
    log_in_as(users(:southwest))
    get institution_path(institutions(:northeast))
    assert_response :forbidden
  end

  test "show() returns HTTP 200 for administrators of the same institution" do
    user = users(:southwest_admin)
    log_in_as(user)
    get institution_path(user.institution)
    assert_response :ok
  end

  test "show() returns HTTP 200 for sysadmins of a different institution" do
    log_in_as(users(:southwest_sysadmin))
    get institution_path(institutions(:northeast))
    assert_response :ok
  end

  # show_access()

  test "show_access() returns HTTP 404 for unscoped requests" do
    host! ::Configuration.instance.main_host
    get institution_access_path(@institution), xhr: true
    assert_response :not_found
  end

  test "show_access() returns HTTP 403 for logged-out users" do
    get institution_access_path(@institution), xhr: true
    assert_response :forbidden
  end

  test "show_access() returns HTTP 403 for unauthorized users" do
    log_in_as(users(:southwest))
    get institution_access_path(@institution), xhr: true
    assert_response :forbidden
  end

  test "show_access() returns HTTP 404 for non-XHR requests" do
    log_in_as(users(:southwest_admin))
    get institution_access_path(@institution)
    assert_response :not_found
  end

  test "show_access() returns HTTP 200 for XHR requests" do
    log_in_as(users(:southwest_admin))
    get institution_access_path(@institution), xhr: true
    assert_response :ok
  end

  test "show_access() respects role limits" do
    log_in_as(users(:southwest_admin))
    get institution_access_path(@institution), xhr: true
    assert_select(".edit-administering-groups")

    get institution_access_path(@institution, role: Role::LOGGED_OUT), xhr: true
    assert_select(".edit-administering-groups", false)
  end

  # show_authentication()

  test "show_authentication() returns HTTP 404 for unscoped requests" do
    host! ::Configuration.instance.main_host
    get institution_authentication_path(@institution), xhr: true
    assert_response :not_found
  end

  test "show_authentication() returns HTTP 403 for logged-out users" do
    get institution_authentication_path(@institution), xhr: true
    assert_response :forbidden
  end

  test "show_authentication() returns HTTP 403 for unauthorized users" do
    log_in_as(users(:southwest))
    get institution_authentication_path(@institution), xhr: true
    assert_response :forbidden
  end

  test "show_authentication() returns HTTP 200 for authorized users" do
    log_in_as(users(:southwest_admin))
    get institution_authentication_path(@institution), xhr: true
    assert_response :ok
  end

  # show_buried_items()

  test "show_buried_items() returns HTTP 404 for unscoped requests" do
    host! ::Configuration.instance.main_host
    get institution_buried_items_path(@institution), xhr: true
    assert_response :not_found
  end

  test "show_buried_items() returns HTTP 403 for logged-out users" do
    get institution_buried_items_path(@institution), xhr: true
    assert_response :forbidden
  end

  test "show_buried_items() returns HTTP 403 for unauthorized users" do
    log_in_as(users(:southwest))
    get institution_buried_items_path(@institution), xhr: true
    assert_response :forbidden
  end

  test "show_buried_items() returns HTTP 200 for authorized users" do
    log_in_as(users(:southwest_admin))
    get institution_buried_items_path(@institution), xhr: true
    assert_response :ok
  end

  # show_depositing()

  test "show_depositing() returns HTTP 404 for unscoped requests" do
    host! ::Configuration.instance.main_host
    get institution_depositing_path(@institution), xhr: true
    assert_response :not_found
  end

  test "show_depositing() returns HTTP 403 for logged-out users" do
    get institution_depositing_path(@institution), xhr: true
    assert_response :forbidden
  end

  test "show_depositing() returns HTTP 403 for unauthorized users" do
    log_in_as(users(:southwest))
    get institution_depositing_path(@institution), xhr: true
    assert_response :forbidden
  end

  test "show_depositing() returns HTTP 200 for authorized users" do
    log_in_as(users(:southwest_admin))
    get institution_depositing_path(@institution), xhr: true
    assert_response :ok
  end

  # show_element_mappings()

  test "show_element_mappings() returns HTTP 404 for unscoped requests" do
    host! ::Configuration.instance.main_host
    get institution_element_mappings_path(@institution), xhr: true
    assert_response :not_found
  end

  test "show_element_mappings() returns HTTP 403 for logged-out users" do
    get institution_element_mappings_path(@institution), xhr: true
    assert_response :forbidden
  end

  test "show_element_mappings() returns HTTP 403 for unauthorized users" do
    log_in_as(users(:southwest))
    get institution_element_mappings_path(@institution), xhr: true
    assert_response :forbidden
  end

  test "show_element_mappings() returns HTTP 200 for authorized users" do
    log_in_as(users(:southwest_admin))
    get institution_element_mappings_path(@institution), xhr: true
    assert_response :ok
  end

  # show_element_namespaces()

  test "show_element_namespaces() returns HTTP 404 for unscoped requests" do
    host! ::Configuration.instance.main_host
    get institution_element_namespaces_path(@institution), xhr: true
    assert_response :not_found
  end

  test "show_element_namespaces() returns HTTP 403 for logged-out users" do
    get institution_element_namespaces_path(@institution), xhr: true
    assert_response :forbidden
  end

  test "show_element_namespaces() returns HTTP 403 for unauthorized users" do
    log_in_as(users(:southwest))
    get institution_element_namespaces_path(@institution), xhr: true
    assert_response :forbidden
  end

  test "show_element_namespaces() returns HTTP 200 for authorized users" do
    log_in_as(users(:southwest_sysadmin))
    get institution_element_namespaces_path(@institution), xhr: true
    assert_response :ok
  end

  # show_element_registry()

  test "show_element_registry() returns HTTP 404 for unscoped requests" do
    host! ::Configuration.instance.main_host
    get institution_elements_path(@institution), xhr: true
    assert_response :not_found
  end

  test "show_element_registry() returns HTTP 403 for logged-out users" do
    get institution_elements_path(@institution), xhr: true
    assert_response :forbidden
  end

  test "show_element_registry() returns HTTP 403 for unauthorized users" do
    log_in_as(users(:southwest))
    get institution_elements_path(@institution), xhr: true
    assert_response :forbidden
  end

  test "show_element_registry() returns HTTP 200 for authorized users" do
    log_in_as(users(:southwest_sysadmin))
    get institution_elements_path(@institution), xhr: true
    assert_response :ok
  end

  # show_imports()

  test "show_imports() returns HTTP 404 for unscoped requests" do
    host! ::Configuration.instance.main_host
    get institution_imports_path(@institution), xhr: true
    assert_response :not_found
  end

  test "show_imports() returns HTTP 403 for logged-out users" do
    get institution_imports_path(@institution), xhr: true
    assert_response :forbidden
  end

  test "show_imports() returns HTTP 403 for unauthorized users" do
    log_in_as(users(:southwest))
    get institution_imports_path(@institution), xhr: true
    assert_response :forbidden
  end

  test "show_imports() returns HTTP 200 for authorized users" do
    log_in_as(users(:southwest_sysadmin))
    get institution_imports_path(@institution), xhr: true
    assert_response :ok
  end

  # show_index_pages()

  test "show_index_pages() returns HTTP 404 for unscoped requests" do
    host! ::Configuration.instance.main_host
    get institution_index_pages_path(@institution), xhr: true
    assert_response :not_found
  end

  test "show_index_pages() returns HTTP 403 for logged-out users" do
    get institution_index_pages_path(@institution), xhr: true
    assert_response :forbidden
  end

  test "show_index_pages() returns HTTP 403 for unauthorized users" do
    log_in_as(users(:southwest))
    get institution_index_pages_path(@institution), xhr: true
    assert_response :forbidden
  end

  test "show_index_pages() returns HTTP 200 for authorized users" do
    log_in_as(users(:southwest_sysadmin))
    get institution_index_pages_path(@institution), xhr: true
    assert_response :ok
  end

  # show_invitees()

  test "show_invitees() returns HTTP 404 for unscoped requests" do
    host! ::Configuration.instance.main_host
    get institution_invitees_path(@institution), xhr: true
    assert_response :not_found
  end

  test "show_invitees() returns HTTP 403 for logged-out users" do
    get institution_invitees_path(@institution), xhr: true
    assert_response :forbidden
  end

  test "show_invitees() returns HTTP 403 for unauthorized users" do
    log_in_as(users(:southwest))
    get institution_invitees_path(@institution), xhr: true
    assert_response :forbidden
  end

  test "show_invitees() returns HTTP 200 for authorized users" do
    log_in_as(users(:southwest_admin))
    get institution_invitees_path(@institution), xhr: true
    assert_response :ok
  end

  # show_metadata_profiles()

  test "show_metadata_profiles() returns HTTP 404 for unscoped requests" do
    host! ::Configuration.instance.main_host
    get institution_metadata_profiles_path(@institution), xhr: true
    assert_response :not_found
  end

  test "show_metadata_profiles() returns HTTP 403 for logged-out users" do
    get institution_metadata_profiles_path(@institution), xhr: true
    assert_response :forbidden
  end

  test "show_metadata_profiles() returns HTTP 403 for unauthorized users" do
    log_in_as(users(:southwest))
    get institution_metadata_profiles_path(@institution), xhr: true
    assert_response :forbidden
  end

  test "show_metadata_profiles() returns HTTP 200 for authorized users" do
    log_in_as(users(:southwest_sysadmin))
    get institution_metadata_profiles_path(@institution), xhr: true
    assert_response :ok
  end

  # show_prebuilt_searches()

  test "show_prebuilt_searches() returns HTTP 404 for unscoped requests" do
    host! ::Configuration.instance.main_host
    get institution_prebuilt_searches_path(@institution), xhr: true
    assert_response :not_found
  end

  test "show_prebuilt_searches() returns HTTP 403 for logged-out users" do
    get institution_prebuilt_searches_path(@institution), xhr: true
    assert_response :forbidden
  end

  test "show_prebuilt_searches() returns HTTP 403 for unauthorized users" do
    log_in_as(users(:southwest))
    get institution_prebuilt_searches_path(@institution), xhr: true
    assert_response :forbidden
  end

  test "show_prebuilt_searches() returns HTTP 200 for authorized users" do
    log_in_as(users(:southwest_sysadmin))
    get institution_prebuilt_searches_path(@institution), xhr: true
    assert_response :ok
  end

  # show_preservation()

  test "show_preservation() returns HTTP 404 for unscoped requests" do
    host! ::Configuration.instance.main_host
    get institution_preservation_path(@institution), xhr: true
    assert_response :not_found
  end

  test "show_preservation() returns HTTP 403 for logged-out users" do
    get institution_preservation_path(@institution), xhr: true
    assert_response :forbidden
  end

  test "show_preservation() returns HTTP 403 for unauthorized users" do
    log_in_as(users(:southwest))
    get institution_preservation_path(@institution), xhr: true
    assert_response :forbidden
  end

  test "show_preservation() returns HTTP 200 for authorized users" do
    log_in_as(users(:southwest_sysadmin))
    get institution_preservation_path(@institution), xhr: true
    assert_response :ok
  end

  # show_private_items()

  test "show_private_items() returns HTTP 404 for unscoped requests" do
    host! ::Configuration.instance.main_host
    get institution_private_items_path(@institution), xhr: true
    assert_response :not_found
  end

  test "show_private_items() returns HTTP 403 for logged-out users" do
    get institution_private_items_path(@institution), xhr: true
    assert_response :forbidden
  end

  test "show_private_items() returns HTTP 403 for unauthorized users" do
    log_in_as(users(:southwest))
    get institution_private_items_path(@institution), xhr: true
    assert_response :forbidden
  end

  test "show_private_items() returns HTTP 200 for authorized users" do
    log_in_as(users(:southwest_admin))
    get institution_private_items_path(@institution), xhr: true
    assert_response :ok
  end

  # show_properties()

  test "show_properties() returns HTTP 404 for unscoped requests" do
    host! ::Configuration.instance.main_host
    get institution_properties_path(@institution), xhr: true
    assert_response :not_found
  end

  test "show_properties() returns HTTP 403 for logged-out users" do
    get institution_properties_path(@institution), xhr: true
    assert_response :forbidden
  end

  test "show_properties() returns HTTP 403 for unauthorized users" do
    log_in_as(users(:southwest))
    get institution_properties_path(@institution), xhr: true
    assert_response :forbidden
  end

  test "show_properties() returns HTTP 200 for authorized users" do
    log_in_as(users(:southwest_admin))
    get institution_properties_path(@institution), xhr: true
    assert_response :ok
  end

  # show_rejected_items()

  test "show_rejected_items() returns HTTP 404 for unscoped requests" do
    host! ::Configuration.instance.main_host
    get institution_rejected_items_path(@institution), xhr: true
    assert_response :not_found
  end

  test "show_rejected_items() returns HTTP 403 for logged-out users" do
    get institution_rejected_items_path(@institution), xhr: true
    assert_response :forbidden
  end

  test "show_rejected_items() returns HTTP 403 for unauthorized users" do
    log_in_as(users(:southwest))
    get institution_rejected_items_path(@institution), xhr: true
    assert_response :forbidden
  end

  test "show_rejected_items() returns HTTP 200 for authorized users" do
    log_in_as(users(:southwest_admin))
    get institution_rejected_items_path(@institution), xhr: true
    assert_response :ok
  end

  # show_review_submissions()

  test "show_review_submissions() returns HTTP 404 for unscoped requests" do
    host! ::Configuration.instance.main_host
    get institution_review_submissions_path(@institution), xhr: true
    assert_response :not_found
  end

  test "show_review_submissions() returns HTTP 403 for logged-out users" do
    get institution_review_submissions_path(@institution), xhr: true
    assert_response :forbidden
  end

  test "show_review_submissions() returns HTTP 403 for unauthorized users" do
    log_in_as(users(:southwest))
    get institution_review_submissions_path(@institution), xhr: true
    assert_response :forbidden
  end

  test "show_review_submissions() returns HTTP 200 for authorized users" do
    log_in_as(users(:southwest_admin))
    get institution_review_submissions_path(@institution), xhr: true
    assert_response :ok
  end

  # show_settings()

  test "show_settings() returns HTTP 404 for unscoped requests" do
    host! ::Configuration.instance.main_host
    get institution_settings_path(@institution), xhr: true
    assert_response :not_found
  end

  test "show_settings() returns HTTP 403 for logged-out users" do
    get institution_settings_path(@institution), xhr: true
    assert_response :forbidden
  end

  test "show_settings() returns HTTP 403 for unauthorized users" do
    log_in_as(users(:southwest))
    get institution_settings_path(@institution), xhr: true
    assert_response :forbidden
  end

  test "show_settings() returns HTTP 200 for authorized users" do
    log_in_as(users(:southwest_admin))
    get institution_settings_path(@institution), xhr: true
    assert_response :ok
  end

  # show_statistics()

  test "show_statistics() returns HTTP 404 for unscoped requests" do
    host! ::Configuration.instance.main_host
    get institution_statistics_path(@institution), xhr: true
    assert_response :not_found
  end

  test "show_statistics() returns HTTP 403 for logged-out users" do
    get institution_statistics_path(@institution), xhr: true
    assert_response :forbidden
  end

  test "show_statistics() returns HTTP 403 for unauthorized users" do
    log_in_as(users(:southwest))
    get institution_statistics_path(@institution), xhr: true
    assert_response :forbidden
  end

  test "show_statistics() returns HTTP 200 for authorized users" do
    log_in_as(users(:southwest_admin))
    get institution_statistics_path(@institution), xhr: true
    assert_response :ok
  end

  # show_submission_profiles()

  test "show_submission_profiles() returns HTTP 404 for unscoped requests" do
    host! ::Configuration.instance.main_host
    get institution_submission_profiles_path(@institution), xhr: true
    assert_response :not_found
  end

  test "show_submission_profiles() returns HTTP 403 for logged-out users" do
    get institution_submission_profiles_path(@institution), xhr: true
    assert_response :forbidden
  end

  test "show_submission_profiles() returns HTTP 403 for unauthorized users" do
    log_in_as(users(:southwest))
    get institution_submission_profiles_path(@institution), xhr: true
    assert_response :forbidden
  end

  test "show_submission_profiles() returns HTTP 200 for authorized users" do
    log_in_as(users(:southwest_sysadmin))
    get institution_submission_profiles_path(@institution), xhr: true
    assert_response :ok
  end

  # show_submissions_in_progress()

  test "show_submissions_in_progress() returns HTTP 404 for unscoped requests" do
    host! ::Configuration.instance.main_host
    get institution_submissions_in_progress_path(@institution), xhr: true
    assert_response :not_found
  end

  test "show_submissions_in_progress() returns HTTP 403 for logged-out users" do
    get institution_submissions_in_progress_path(@institution), xhr: true
    assert_response :forbidden
  end

  test "show_submissions_in_progress() returns HTTP 403 for unauthorized users" do
    log_in_as(users(:southwest))
    get institution_submissions_in_progress_path(@institution), xhr: true
    assert_response :forbidden
  end

  test "show_submissions_in_progress() returns HTTP 200 for authorized users" do
    log_in_as(users(:southwest_admin))
    get institution_submissions_in_progress_path(@institution), xhr: true
    assert_response :ok
  end

  # show_theme()

  test "show_theme() returns HTTP 404 for unscoped requests" do
    host! ::Configuration.instance.main_host
    get institution_theme_path(@institution), xhr: true
    assert_response :not_found
  end

  test "show_theme() returns HTTP 403 for logged-out users" do
    get institution_theme_path(@institution), xhr: true
    assert_response :forbidden
  end

  test "show_theme() returns HTTP 403 for unauthorized users" do
    log_in_as(users(:southwest))
    get institution_theme_path(@institution), xhr: true
    assert_response :forbidden
  end

  test "show_theme() returns HTTP 200 for authorized users" do
    log_in_as(users(:southwest_admin))
    get institution_theme_path(@institution), xhr: true
    assert_response :ok
  end

  # show_units()

  test "show_units() returns HTTP 404 for unscoped requests" do
    host! ::Configuration.instance.main_host
    get institution_units_path(@institution), xhr: true
    assert_response :not_found
  end

  test "show_units() returns HTTP 403 for logged-out users" do
    get institution_units_path(@institution), xhr: true
    assert_response :forbidden
  end

  test "show_units() returns HTTP 403 for unauthorized users" do
    log_in_as(users(:southwest))
    get institution_units_path(@institution), xhr: true
    assert_response :forbidden
  end

  test "show_units() returns HTTP 200 for authorized users" do
    log_in_as(users(:southwest_sysadmin))
    get institution_units_path(@institution), xhr: true
    assert_response :ok
  end

  # show_usage()

  test "show_usage() returns HTTP 404 for unscoped requests" do
    host! ::Configuration.instance.main_host
    get institution_usage_path(@institution), xhr: true
    assert_response :not_found
  end

  test "show_usage() returns HTTP 403 for logged-out users" do
    get institution_usage_path(@institution), xhr: true
    assert_response :forbidden
  end

  test "show_usage() returns HTTP 403 for unauthorized users" do
    log_in_as(users(:southwest))
    get institution_usage_path(@institution), xhr: true
    assert_response :forbidden
  end

  test "show_usage() returns HTTP 200 for authorized users" do
    log_in_as(users(:southwest_admin))
    get institution_usage_path(@institution), xhr: true
    assert_response :ok
  end

  # show_user_groups()

  test "show_user_groups() returns HTTP 404 for unscoped requests" do
    host! ::Configuration.instance.main_host
    get institution_user_groups_path(@institution), xhr: true
    assert_response :not_found
  end

  test "show_user_groups() returns HTTP 403 for logged-out users" do
    get institution_user_groups_path(@institution), xhr: true
    assert_response :forbidden
  end

  test "show_user_groups() returns HTTP 403 for unauthorized users" do
    log_in_as(users(:southwest))
    get institution_user_groups_path(@institution), xhr: true
    assert_response :forbidden
  end

  test "show_user_groups() returns HTTP 200 for authorized users" do
    log_in_as(users(:southwest_admin))
    get institution_user_groups_path(@institution), xhr: true
    assert_response :ok
  end

  # show_users()

  test "show_users() returns HTTP 404 for unscoped requests" do
    host! ::Configuration.instance.main_host
    get institution_users_path(@institution), xhr: true
    assert_response :not_found
  end

  test "show_users() returns HTTP 403 for logged-out users" do
    get institution_users_path(@institution), xhr: true
    assert_response :forbidden
  end

  test "show_users() returns HTTP 403 for unauthorized users" do
    log_in_as(users(:southwest))
    get institution_users_path(@institution), xhr: true
    assert_response :forbidden
  end

  test "show_users() returns HTTP 200 for authorized users" do
    log_in_as(users(:southwest_admin))
    get institution_users_path(@institution), xhr: true
    assert_response :ok
  end

  # show_vocabularies()

  test "show_vocabularies() returns HTTP 404 for unscoped requests" do
    host! ::Configuration.instance.main_host
    get institution_vocabularies_path(@institution), xhr: true
    assert_response :not_found
  end

  test "show_vocabularies() returns HTTP 403 for logged-out users" do
    get institution_vocabularies_path(@institution), xhr: true
    assert_response :forbidden
  end

  test "show_vocabularies() returns HTTP 403 for unauthorized users" do
    log_in_as(users(:southwest))
    get institution_vocabularies_path(@institution), xhr: true
    assert_response :forbidden
  end

  test "show_vocabularies() returns HTTP 200 for authorized users" do
    log_in_as(users(:southwest_sysadmin))
    get institution_vocabularies_path(@institution), xhr: true
    assert_response :ok
  end

  # show_withdrawn_items()

  test "show_withdrawn_items() returns HTTP 404 for unscoped requests" do
    host! ::Configuration.instance.main_host
    get institution_withdrawn_items_path(@institution), xhr: true
    assert_response :not_found
  end

  test "show_withdrawn_items() returns HTTP 403 for logged-out users" do
    get institution_withdrawn_items_path(@institution), xhr: true
    assert_response :forbidden
  end

  test "show_withdrawn_items() returns HTTP 403 for unauthorized users" do
    log_in_as(users(:southwest))
    get institution_withdrawn_items_path(@institution), xhr: true
    assert_response :forbidden
  end

  test "show_withdrawn_items() returns HTTP 200 for authorized users" do
    log_in_as(users(:southwest_admin))
    get institution_withdrawn_items_path(@institution), xhr: true
    assert_response :ok
  end

  # statistics_by_range()

  test "statistics_by_range() returns HTTP 404 for unscoped requests" do
    host! ::Configuration.instance.main_host
    get institution_statistics_by_range_path(@institution)
    assert_response :not_found
  end

  test "statistics_by_range() redirects to root page for logged-out users" do
    get institution_statistics_by_range_path(@institution)
    assert_redirected_to @institution.scope_url
  end

  test "statistics_by_range() returns HTTP 403 for unauthorized users" do
    log_in_as(users(:southwest))
    get institution_statistics_by_range_path(@institution)
    assert_response :forbidden
  end

  test "statistics_by_range() returns HTTP 200" do
    log_in_as(users(:southwest_admin))
    get institution_statistics_by_range_path(@institution), params: {
      from_year:  2008,
      from_month: 1,
      to_year:    2008,
      to_month:   12
    }
    assert_response :ok
  end

  test "statistics_by_range() returns HTTP 400 for illegal arguments" do
    log_in_as(users(:southwest_admin))
    get institution_statistics_by_range_path(@institution), params: {
      from_year:  2008,
      from_month: 1,
      to_year:    2005,
      to_month:   1
    }
    assert_response :bad_request
  end

  # supply_saml_configuration()

  test "supply_saml_configuration() returns HTTP 404 for unscoped requests" do
    host! ::Configuration.instance.main_host
    get institution_supply_saml_configuration_path(@institution), xhr: true
    assert_response :not_found
  end

  test "supply_saml_configuration() returns HTTP 403 for logged-out users" do
    get institution_supply_saml_configuration_path(@institution), xhr: true
    assert_response :forbidden
  end

  test "supply_saml_configuration() returns HTTP 403 for unauthorized users" do
    log_in_as(users(:southwest))
    get institution_supply_saml_configuration_path(@institution), xhr: true
    assert_response :forbidden
  end

  test "supply_saml_configuration() returns HTTP 200" do
    log_in_as(users(:southwest_admin))
    get institution_supply_saml_configuration_path(@institution), xhr: true
    assert_response :ok
  end

  # update_deposit_agreement_questions()

  test "update_deposit_agreement_questions() returns HTTP 404 for unscoped
  requests" do
    host! ::Configuration.instance.main_host
    patch institution_deposit_agreement_questions_path(@institution)
    assert_response :not_found
  end

  test "update_deposit_agreement_questions() redirects to root page for
  logged-out users" do
    patch institution_deposit_agreement_questions_path(@institution)
    assert_redirected_to @institution.scope_url
  end

  test "update_deposit_agreement_questions() returns HTTP 403 for unauthorized
  users" do
    log_in_as(users(:southwest))
    patch institution_deposit_agreement_questions_path(@institution)
    assert_response :forbidden
  end

  test "update_deposit_agreement_questions() updates an institution's deposit
  agreement questions" do
    user = users(:southwest_admin)
    log_in_as(user)
    institution = user.institution
    patch institution_deposit_agreement_questions_path(institution),
          xhr: true,
          params: {
            questions: {
              "0": {
                text: "When?",
                help_text: "?",
                responses: {
                  "0": {
                    text: "Then",
                    success: "true"
                  },
                  "1": {
                    text: "Now",
                    success: "false"
                  },
                }
              }
            }
          }
    institution.reload
    assert_equal 1, institution.deposit_agreement_questions.count
    q = institution.deposit_agreement_questions.first
    assert_equal 2, q.responses.count
    r = q.responses.first
    assert_equal "Then", r.text
    assert r.success
  end

  test "update_deposit_agreement_questions() returns HTTP 200" do
    user = users(:southwest_admin)
    log_in_as(user)
    institution = user.institution
    patch institution_deposit_agreement_questions_path(institution),
          xhr: true,
          params: {
            questions: {
              "0": {
                text: "When?",
                help_text: "?",
                responses: {
                  "0": {
                    text: "Then",
                    success: "true"
                  }
                }
              }
            }
          }
    assert_response :ok
  end

  test "update_deposit_agreement_questions() returns HTTP 400 for illegal
  arguments" do
    log_in_as(users(:southwest_admin))
    patch institution_deposit_agreement_questions_path(@institution),
          xhr: true,
          params: {
            bogus: {
            }
          }
    assert_response :bad_request
  end

  test "update_deposit_agreement_questions() returns HTTP 404 for nonexistent
  institutions" do
    log_in_as(users(:southwest_admin))
    patch "/institutions/bogus/deposit-agreement-questions"
    assert_response :not_found
  end

  # update_preservation()

  test "update_preservation() returns HTTP 404 for unscoped requests" do
    host! ::Configuration.instance.main_host
    patch institution_preservation_path(@institution)
    assert_response :not_found
  end

  test "update_preservation() redirects to root page for logged-out users" do
    patch institution_preservation_path(@institution)
    assert_redirected_to @institution.scope_url
  end

  test "update_preservation() returns HTTP 403 for unauthorized users" do
    log_in_as(users(:southwest))
    patch institution_preservation_path(@institution)
    assert_response :forbidden
  end

  test "update_preservation() updates an institution's properties" do
    user = users(:southwest_sysadmin)
    log_in_as(user)
    institution = user.institution
    patch institution_preservation_path(institution),
          xhr: true,
          params: {
            institution: {
              medusa_file_group_id: 34
            }
          }
    institution.reload
    assert_equal 34, institution.medusa_file_group_id
  end

  test "update_preservation() returns HTTP 200" do
    user = users(:southwest_sysadmin)
    log_in_as(user)
    institution = user.institution
    patch institution_preservation_path(institution),
          xhr: true,
          params: {
            institution: {
              medusa_file_group_id: 34
            }
          }
    assert_response :ok
  end

  test "update_preservation() returns HTTP 400 for illegal arguments" do
    log_in_as(users(:southwest_sysadmin))
    patch institution_preservation_path(@institution),
          xhr: true,
          params: {
            institution: {
              medusa_file_group_id: "not a number" # invalid
            }
          }
    assert_response :bad_request
  end

  test "update_preservation() returns HTTP 404 for nonexistent institutions" do
    log_in_as(users(:southwest_admin))
    patch "/institutions/bogus/preservation"
    assert_response :not_found
  end

  # update_properties()

  test "update_properties() returns HTTP 404 for unscoped requests" do
    host! ::Configuration.instance.main_host
    patch institution_properties_path(@institution)
    assert_response :not_found
  end

  test "update_properties() redirects to root page for logged-out users" do
    patch institution_properties_path(@institution)
    assert_redirected_to @institution.scope_url
  end

  test "update_properties() returns HTTP 403 for unauthorized users" do
    log_in_as(users(:southwest))
    patch institution_properties_path(@institution)
    assert_response :forbidden
  end

  test "update_properties() updates an institution's properties" do
    user = users(:southwest_sysadmin)
    log_in_as(user)
    institution = user.institution
    patch institution_properties_path(institution),
          xhr: true,
          params: {
            institution: {
              name: "New Institution",
              fqdn: "new.org"
            }
          }
    institution.reload
    assert_equal "New Institution", institution.name
  end

  test "update_properties() returns HTTP 200" do
    user = users(:southwest_sysadmin)
    log_in_as(user)
    institution = user.institution
    patch institution_properties_path(institution),
          xhr: true,
          params: {
            institution: {
              name: "New Institution",
              fqdn: "new.org"
            }
          }
    assert_response :ok
  end

  test "update_properties() returns HTTP 400 for illegal arguments" do
    log_in_as(users(:southwest_sysadmin))
    patch institution_properties_path(@institution),
          xhr: true,
          params: {
            institution: {
              name: "" # invalid
            }
          }
    assert_response :bad_request
  end

  test "update_properties() returns HTTP 404 for nonexistent institutions" do
    log_in_as(users(:southwest_admin))
    patch "/institutions/bogus/properties"
    assert_response :not_found
  end

  # update_settings()

  test "update_settings() returns HTTP 404 for unscoped requests" do
    host! ::Configuration.instance.main_host
    patch institution_settings_path(@institution)
    assert_response :not_found
  end

  test "update_settings() redirects to root page for logged-out users" do
    patch institution_settings_path(@institution)
    assert_redirected_to @institution.scope_url
  end

  test "update_settings() returns HTTP 403 for unauthorized users" do
    log_in_as(users(:southwest))
    patch institution_settings_path(@institution)
    assert_response :forbidden
  end

  test "update_settings() updates an institution's settings" do
    user = users(:southwest_admin)
    log_in_as(user)
    institution = user.institution
    patch institution_settings_path(institution),
          xhr: true,
          params: {
            institution: {
              link_hover_color: "#335599"
            }
          }
    institution.reload
    assert_equal "#335599", institution.link_hover_color
  end

  test "update_settings() returns HTTP 200" do
    user = users(:southwest_admin)
    log_in_as(user)
    institution = user.institution
    patch institution_settings_path(institution),
          xhr: true,
          params: {
            institution: {
              name:               "New Institution",
              fqdn:               "new.org",
              saml_idp_entity_id: "new"
            }
          }
    assert_response :ok
  end

  test "update_settings() returns HTTP 400 for illegal arguments" do
    log_in_as(users(:southwest_admin))
    patch institution_settings_path(@institution),
          xhr: true,
          params: {
            institution: {
              link_hover_color: "" # invalid
            }
          }
    assert_response :bad_request
  end

  test "update_settings() returns HTTP 404 for nonexistent institutions" do
    log_in_as(users(:southwest_admin))
    patch "/institutions/bogus/settings"
    assert_response :not_found
  end

end
