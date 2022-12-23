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

  test "create() redirects to root page for logged-out users" do
    post institutions_path
    assert_redirected_to @institution.scope_url
  end

  test "create() returns HTTP 403 for unauthorized users" do
    log_in_as(users(:norights))
    post institutions_path,
         xhr: true,
         params: {
           institution: {
             name: "New Institution",
             key: "new",
             fqdn: "new.org",
             org_dn: "new"
           }
         }
    assert_response :forbidden
  end

  test "create() returns HTTP 200 for sysadmins" do
    log_in_as(users(:local_sysadmin))
    post institutions_path,
         xhr: true,
         params: {
           institution: {
             name:             "New Institution",
             service_name:     "New",
             key:              "new",
             fqdn:             "new.org",
             org_dn:           "new",
             main_website_url: "https://new.org"
           }
         }
    assert_response :ok
  end

  test "create() creates an institution" do
    user = users(:local_sysadmin)
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
               org_dn:           "new",
               main_website_url: "https://new.org"
             }
           }
    end
  end

  test "create() returns HTTP 400 for illegal arguments" do
    log_in_as(users(:local_sysadmin))
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

  test "destroy() redirects to root page for logged-out users" do
    delete institution_path(@institution)
    assert_redirected_to @institution.scope_url
  end

  test "destroy() returns HTTP 403 for unauthorized users" do
    log_in_as(users(:norights))
    delete institution_path(@institution)
    assert_response :forbidden
  end

  test "destroy() destroys the institution" do
    log_in_as(users(:local_sysadmin))
    @institution.nuke!
    delete institution_path(@institution)
    assert_raises ActiveRecord::RecordNotFound do
      Institution.find(@institution.id)
    end
  end

  test "destroy() returns HTTP 302 for an existing institution" do
    log_in_as(users(:local_sysadmin))
    delete institution_path(@institution)
    assert_redirected_to institutions_path
  end

  test "destroy() returns HTTP 404 for a missing institution" do
    log_in_as(users(:local_sysadmin))
    delete "/institutions/bogus"
    assert_response :not_found
  end

  # edit_administrators()

  test "edit_administrators() returns HTTP 403 for logged-out users" do
    get institution_edit_administrators_path(@institution), xhr: true
    assert_response :forbidden
  end

  test "edit_administrators() returns HTTP 403 for unauthorized users" do
    log_in_as(users(:norights))
    get institution_edit_administrators_path(@institution), xhr: true
    assert_response :forbidden
  end

  test "edit_administrators() returns HTTP 404 for non-XHR requests" do
    log_in_as(users(:local_sysadmin))
    get institution_edit_administrators_path(@institution)
    assert_response :not_found
  end

  test "edit_administrators() returns HTTP 200 for XHR requests" do
    log_in_as(users(:local_sysadmin))
    get institution_edit_administrators_path(@institution), xhr: true
    assert_response :ok
  end

  # edit_preservation()

  test "edit_preservation() returns HTTP 403 for logged-out users" do
    get institution_edit_preservation_path(@institution), xhr: true
    assert_response :forbidden
  end

  test "edit_preservation() returns HTTP 403 for unauthorized users" do
    log_in_as(users(:norights))
    get institution_edit_preservation_path(@institution), xhr: true
    assert_response :forbidden
  end

  test "edit_preservation() returns HTTP 200" do
    log_in_as(users(:local_sysadmin))
    get institution_edit_preservation_path(@institution), xhr: true
    assert_response :ok
  end

  # edit_properties()

  test "edit_properties() returns HTTP 403 for logged-out users" do
    get institution_edit_properties_path(@institution), xhr: true
    assert_response :forbidden
  end

  test "edit_properties() returns HTTP 403 for unauthorized users" do
    log_in_as(users(:norights))
    get institution_edit_properties_path(@institution), xhr: true
    assert_response :forbidden
  end

  test "edit_properties() returns HTTP 200" do
    log_in_as(users(:local_sysadmin))
    get institution_edit_properties_path(@institution), xhr: true
    assert_response :ok
  end

  # edit_settings()

  test "edit_settings() returns HTTP 403 for logged-out users" do
    get institution_edit_settings_path(@institution), xhr: true
    assert_response :forbidden
  end

  test "edit_settings() returns HTTP 403 for unauthorized users" do
    log_in_as(users(:norights))
    get institution_edit_settings_path(@institution), xhr: true
    assert_response :forbidden
  end

  test "edit_settings() returns HTTP 200" do
    log_in_as(users(:local_sysadmin))
    get institution_edit_settings_path(@institution), xhr: true
    assert_response :ok
  end

  # edit_theme()

  test "edit_theme() returns HTTP 403 for logged-out users" do
    get institution_edit_theme_path(@institution), xhr: true
    assert_response :forbidden
  end

  test "edit_theme() returns HTTP 403 for unauthorized users" do
    log_in_as(users(:norights))
    get institution_edit_theme_path(@institution), xhr: true
    assert_response :forbidden
  end

  test "edit_theme() returns HTTP 404 for non-XHR requests" do
    log_in_as(users(:local_sysadmin))
    get institution_edit_theme_path(@institution)
    assert_response :not_found
  end

  test "edit_theme() returns HTTP 200 for XHR requests" do
    log_in_as(users(:local_sysadmin))
    get institution_edit_theme_path(@institution), xhr: true
    assert_response :ok
  end

  # index()

  test "index() redirects to root page for logged-out users" do
    get institutions_path
    assert_redirected_to @institution.scope_url
  end

  test "index() returns HTTP 403 for unauthorized users" do
    log_in_as(users(:norights))
    get institutions_path
    assert_response :forbidden
  end

  test "index() returns HTTP 200 for sysadmins" do
    log_in_as(users(:local_sysadmin))
    get institutions_path
    assert_response :ok
  end

  # item_download_counts()

  test "item_download_counts() redirects to root page for logged-out users" do
    get institution_item_download_counts_path(@institution)
    assert_redirected_to @institution.scope_url
  end

  test "item_download_counts() returns HTTP 403 for unauthorized users" do
    log_in_as(users(:norights))
    get institution_item_download_counts_path(@institution)
    assert_response :forbidden
  end

  test "item_download_counts() returns HTTP 200" do
    log_in_as(users(:local_sysadmin))
    get institution_item_download_counts_path(@institution)
    assert_response :ok
  end

  # new()

  test "new() redirects to root page for logged-out users" do
    get new_institution_path
    assert_redirected_to @institution.scope_url
  end

  test "new() returns HTTP 403 for unauthorized users" do
    log_in_as(users(:norights))
    get new_institution_path
    assert_response :forbidden
  end

  test "new() returns HTTP 200 for authorized users" do
    log_in_as(users(:local_sysadmin))
    get new_institution_path
    assert_response :ok
  end

  # show()

  test "show() redirects to root page for logged-out users" do
    get institution_path(@institution)
    assert_redirected_to @institution.scope_url
  end

  test "show() redirects to the root page for non-administrators of the same
  institution" do
    user = users(:southwest)
    log_in_as(user)
    get institution_path(@institution)
    assert_redirected_to @institution.scope_url
  end

  test "show() returns HTTP 403 for users of a different institution" do
    log_in_as(users(:uiuc))
    get institution_path(@institution)
    assert_response :forbidden
  end

  test "show() returns HTTP 200 for administrators of the same institution" do
    user = users(:southwest_admin)
    log_in_as(user)
    get institution_path(user.institution)
    assert_response :ok
  end

  test "show() returns HTTP 200 for sysadmins of a different institution" do
    log_in_as(users(:uiuc_sysadmin))
    get institution_path(@institution)
    assert_response :ok
  end

  # show_access()

  test "show_access() returns HTTP 403 for logged-out users" do
    get institution_access_path(@institution), xhr: true
    assert_response :forbidden
  end

  test "show_access() returns HTTP 403 for unauthorized users" do
    log_in_as(users(:norights))
    get institution_access_path(@institution), xhr: true
    assert_response :forbidden
  end

  test "show_access() returns HTTP 404 for non-XHR requests" do
    log_in_as(users(:local_sysadmin))
    get institution_access_path(@institution)
    assert_response :not_found
  end

  test "show_access() returns HTTP 200 for XHR requests" do
    log_in_as(users(:local_sysadmin))
    get institution_access_path(@institution), xhr: true
    assert_response :ok
  end

  test "show_access() respects role limits" do
    log_in_as(users(:southwest_admin))
    get institution_access_path(@institution), xhr: true
    assert_select(".edit-administrators")

    get institution_access_path(@institution, role: Role::LOGGED_OUT), xhr: true
    assert_select(".edit-administrators", false)
  end

  # show_preservation()

  test "show_preservation() returns HTTP 403 for logged-out users" do
    get institution_preservation_path(@institution), xhr: true
    assert_response :forbidden
  end

  test "show_preservation() returns HTTP 403 for unauthorized users" do
    log_in_as(users(:norights))
    get institution_preservation_path(@institution), xhr: true
    assert_response :forbidden
  end

  test "show_preservation() returns HTTP 200 for authorized users" do
    log_in_as(users(:local_sysadmin))
    get institution_preservation_path(@institution), xhr: true
    assert_response :ok
  end

  # show_properties()

  test "show_properties() returns HTTP 403 for logged-out users" do
    get institution_properties_path(@institution), xhr: true
    assert_response :forbidden
  end

  test "show_properties() returns HTTP 403 for unauthorized users" do
    log_in_as(users(:norights))
    get institution_properties_path(@institution), xhr: true
    assert_response :forbidden
  end

  test "show_properties() returns HTTP 200 for authorized users" do
    log_in_as(users(:local_sysadmin))
    get institution_properties_path(@institution), xhr: true
    assert_response :ok
  end

  # show_settings()

  test "show_settings() returns HTTP 403 for logged-out users" do
    get institution_settings_path(@institution), xhr: true
    assert_response :forbidden
  end

  test "show_settings() returns HTTP 403 for unauthorized users" do
    log_in_as(users(:norights))
    get institution_settings_path(@institution), xhr: true
    assert_response :forbidden
  end

  test "show_settings() returns HTTP 200 for authorized users" do
    log_in_as(users(:local_sysadmin))
    get institution_settings_path(@institution), xhr: true
    assert_response :ok
  end

  # show_statistics()

  test "show_statistics() returns HTTP 403 for logged-out users" do
    get institution_statistics_path(@institution), xhr: true
    assert_response :forbidden
  end

  test "show_statistics() returns HTTP 403 for unauthorized users" do
    log_in_as(users(:norights))
    get institution_statistics_path(@institution), xhr: true
    assert_response :forbidden
  end

  test "show_statistics() returns HTTP 200 for authorized users" do
    log_in_as(users(:local_sysadmin))
    get institution_statistics_path(@institution), xhr: true
    assert_response :ok
  end

  # show_theme()

  test "show_theme() returns HTTP 403 for logged-out users" do
    get institution_theme_path(@institution), xhr: true
    assert_response :forbidden
  end

  test "show_theme() returns HTTP 403 for unauthorized users" do
    log_in_as(users(:norights))
    get institution_theme_path(@institution), xhr: true
    assert_response :forbidden
  end

  test "show_theme() returns HTTP 200 for authorized users" do
    log_in_as(users(:local_sysadmin))
    get institution_theme_path(@institution), xhr: true
    assert_response :ok
  end

  # show_users()

  test "show_users() returns HTTP 403 for logged-out users" do
    get institution_users_path(@institution), xhr: true
    assert_response :forbidden
  end

  test "show_users() returns HTTP 403 for unauthorized users" do
    log_in_as(users(:norights))
    get institution_users_path(@institution), xhr: true
    assert_response :forbidden
  end

  test "show_users() returns HTTP 200 for authorized users" do
    log_in_as(users(:local_sysadmin))
    get institution_users_path(@institution), xhr: true
    assert_response :ok
  end

  # statistics_by_range()

  test "statistics_by_range() redirects to root page for logged-out users" do
    get institution_statistics_by_range_path(@institution)
    assert_redirected_to @institution.scope_url
  end

  test "statistics_by_range() returns HTTP 403 for unauthorized users" do
    log_in_as(users(:norights))
    get institution_statistics_by_range_path(@institution)
    assert_response :forbidden
  end

  test "statistics_by_range() returns HTTP 200" do
    log_in_as(users(:local_sysadmin))
    get institution_statistics_by_range_path(@institution), params: {
      from_year:  2008,
      from_month: 1,
      to_year:    2008,
      to_month:   12
    }
    assert_response :ok
  end

  # update_preservation()

  test "update_preservation() redirects to root page for logged-out users" do
    patch institution_preservation_path(@institution)
    assert_redirected_to @institution.scope_url
  end

  test "update_preservation() returns HTTP 403 for unauthorized users" do
    log_in_as(users(:norights))
    patch institution_preservation_path(@institution)
    assert_response :forbidden
  end

  test "update_preservation() updates an institution's properties" do
    user = users(:uiuc_sysadmin)
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
    user = users(:uiuc_sysadmin)
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
    log_in_as(users(:local_sysadmin))
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
    log_in_as(users(:local_sysadmin))
    patch "/institutions/bogus/preservation"
    assert_response :not_found
  end

  # update_properties()

  test "update_properties() redirects to root page for logged-out users" do
    patch institution_properties_path(@institution)
    assert_redirected_to @institution.scope_url
  end

  test "update_properties() returns HTTP 403 for unauthorized users" do
    log_in_as(users(:norights))
    patch institution_properties_path(@institution)
    assert_response :forbidden
  end

  test "update_properties() updates an institution's properties" do
    user = users(:uiuc_sysadmin)
    log_in_as(user)
    institution = user.institution
    patch institution_properties_path(institution),
          xhr: true,
          params: {
            institution: {
              name:   "New Institution",
              fqdn:   "new.org",
              org_dn: "new"
            }
          }
    institution.reload
    assert_equal "New Institution", institution.name
  end

  test "update_properties() returns HTTP 200" do
    user = users(:uiuc_sysadmin)
    log_in_as(user)
    institution = user.institution
    patch institution_properties_path(institution),
          xhr: true,
          params: {
            institution: {
              name: "New Institution",
              fqdn: "new.org",
              org_dn: "new"
            }
          }
    assert_response :ok
  end

  test "update_properties() returns HTTP 400 for illegal arguments" do
    log_in_as(users(:local_sysadmin))
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
    log_in_as(users(:local_sysadmin))
    patch "/institutions/bogus/properties"
    assert_response :not_found
  end

  # update_settings()

  test "update_settings() redirects to root page for logged-out users" do
    patch institution_settings_path(@institution)
    assert_redirected_to @institution.scope_url
  end

  test "update_settings() returns HTTP 403 for unauthorized users" do
    log_in_as(users(:norights))
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
              name: "New Institution",
              fqdn: "new.org",
              org_dn: "new"
            }
          }
    assert_response :ok
  end

  test "update_settings() returns HTTP 400 for illegal arguments" do
    log_in_as(users(:local_sysadmin))
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
    log_in_as(users(:local_sysadmin))
    patch "/institutions/bogus/settings"
    assert_response :not_found
  end

end
