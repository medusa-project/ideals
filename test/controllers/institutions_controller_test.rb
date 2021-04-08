require 'test_helper'

class InstitutionsControllerTest < ActionDispatch::IntegrationTest

  setup do
    setup_elasticsearch
  end

  teardown do
    log_out
  end

  # create()

  test "create() redirects to login page for logged-out users" do
    post institutions_path
    assert_redirected_to login_path
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

  test "create() returns HTTP 200 for authorized users" do
    log_in_as(users(:uiuc_admin))
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
    assert_response :ok
  end

  test "create() creates an institution" do
    user = users(:uiuc_admin)
    log_in_as(user)
    assert_difference "Institution.count" do
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

  test "destroy() redirects to login page for logged-out users" do
    institution = institutions(:somewhere)
    delete institution_path(institution)
    assert_redirected_to login_path
  end

  test "destroy() returns HTTP 403 for unauthorized users" do
    log_in_as(users(:norights))
    institution = institutions(:somewhere)
    delete institution_path(institution)
    assert_response :forbidden
  end

  test "destroy() destroys the institution" do
    log_in_as(users(:local_sysadmin))
    institution = institutions(:empty)
    delete institution_path(institution)
    assert_raises ActiveRecord::RecordNotFound do
      Institution.find(institution.id)
    end
  end

  test "destroy() returns HTTP 302 for an existing institution" do
    log_in_as(users(:local_sysadmin))
    institution = institutions(:somewhere)
    delete institution_path(institution)
    assert_redirected_to institutions_path
  end

  test "destroy() returns HTTP 404 for a missing institution" do
    log_in_as(users(:local_sysadmin))
    delete "/institutions/bogus"
    assert_response :not_found
  end

  # edit()

  test "edit redirects to login page for logged-out users" do
    institution = institutions(:somewhere)
    get edit_institution_path(institution), xhr: true
    assert_redirected_to login_path
  end

  test "edit() returns HTTP 403 for unauthorized users" do
    log_in_as(users(:norights))
    institution = institutions(:somewhere)
    get edit_institution_path(institution), xhr: true
    assert_response :forbidden
  end

  test "edit() returns HTTP 200" do
    log_in_as(users(:local_sysadmin))
    institution = institutions(:somewhere)
    get edit_institution_path(institution), xhr: true
    assert_response :ok
  end

  # index()

  test "index() redirects to login page for logged-out users" do
    get institutions_path
    assert_redirected_to login_path
  end

  test "index() returns HTTP 403 for unauthorized users" do
    log_in_as(users(:norights))
    get institutions_path
    assert_response :forbidden
  end

  test "index() returns HTTP 200 for authorized users" do
    log_in_as(users(:uiuc_admin))
    get institutions_path
    assert_response :ok
  end

  # item_download_counts()

  test "item_download_counts() redirects to login page for logged-out users" do
    get institution_item_download_counts_path(institutions(:somewhere))
    assert_redirected_to login_path
  end

  test "item_download_counts() returns HTTP 403 for unauthorized users" do
    log_in_as(users(:norights))
    get institution_item_download_counts_path(institutions(:somewhere))
    assert_response :forbidden
  end

  test "item_download_counts() returns HTTP 200" do
    log_in_as(users(:local_sysadmin))
    get institution_item_download_counts_path(institutions(:somewhere))
    assert_response :ok
  end

  # new()

  test "new() redirects to login page for logged-out users" do
    get new_institution_path
    assert_redirected_to login_path
  end

  test "new() returns HTTP 403 for unauthorized users" do
    log_in_as(users(:norights))
    get new_institution_path
    assert_response :forbidden
  end

  test "new() returns HTTP 200 for authorized users" do
    log_in_as(users(:uiuc_admin))
    get new_institution_path
    assert_response :ok
  end

  # show()

  test "show() redirects to login page for logged-out users" do
    get institution_path(institutions(:somewhere))
    assert_redirected_to login_path
  end

  test "show() returns HTTP 403 for unauthorized users" do
    log_in_as(users(:uiuc))
    get institution_path(institutions(:somewhere))
    assert_response :forbidden
  end

  test "show() returns HTTP 200 for authorized users" do
    log_in_as(users(:uiuc_admin))
    get institution_path(institutions(:somewhere))
    assert_response :ok
  end

  # show_properties()

  test "show_properties() redirects to login page for logged-out users" do
    get institution_properties_path(institutions(:somewhere)), xhr: true
    assert_redirected_to login_path
  end

  test "show_properties() returns HTTP 403 for unauthorized users" do
    log_in_as(users(:norights))
    get institution_properties_path(institutions(:somewhere)), xhr: true
    assert_response :forbidden
  end

  test "show_properties() returns HTTP 200 for authorized users" do
    log_in_as(users(:local_sysadmin))
    get institution_properties_path(institutions(:somewhere)), xhr: true
    assert_response :ok
  end

  # show_statistics()

  test "show_statistics() redirects to login page for logged-out users" do
    get institution_statistics_path(institutions(:somewhere)), xhr: true
    assert_redirected_to login_path
  end

  test "show_statistics() returns HTTP 403 for unauthorized users" do
    log_in_as(users(:norights))
    get institution_statistics_path(institutions(:somewhere)), xhr: true
    assert_response :forbidden
  end

  test "show_statistics() returns HTTP 200 for authorized users" do
    log_in_as(users(:local_sysadmin))
    get institution_statistics_path(institutions(:somewhere)), xhr: true
    assert_response :ok
  end

  # show_users()

  test "show_users() redirects to login page for logged-out users" do
    get institution_users_path(institutions(:somewhere)), xhr: true
    assert_redirected_to login_path
  end

  test "show_users() returns HTTP 403 for unauthorized users" do
    log_in_as(users(:norights))
    get institution_users_path(institutions(:somewhere)), xhr: true
    assert_response :forbidden
  end

  test "show_users() returns HTTP 200 for authorized users" do
    log_in_as(users(:local_sysadmin))
    get institution_users_path(institutions(:somewhere)), xhr: true
    assert_response :ok
  end

  # statistics_by_range()

  test "statistics_by_range() redirects to login page for logged-out users" do
    get institution_statistics_by_range_path(institutions(:somewhere))
    assert_redirected_to login_path
  end

  test "statistics_by_range() returns HTTP 403 for unauthorized users" do
    log_in_as(users(:norights))
    get institution_statistics_by_range_path(institutions(:somewhere))
    assert_response :forbidden
  end

  test "statistics_by_range() returns HTTP 200" do
    log_in_as(users(:local_sysadmin))
    get institution_statistics_by_range_path(institutions(:somewhere))
    assert_response :ok
  end

  # update()

  test "update() redirects to login page for logged-out users" do
    institution = institutions(:somewhere)
    patch institution_path(institution)
    assert_redirected_to login_path
  end

  test "update() returns HTTP 403 for unauthorized users" do
    log_in_as(users(:norights))
    institution = institutions(:somewhere)
    patch institution_path(institution)
    assert_response :forbidden
  end

  test "update() updates an institution" do
    user = users(:uiuc_admin)
    log_in_as(user)
    institution = user.institution
    patch institution_path(institution),
          xhr: true,
          params: {
            institution: {
              name: "New Institution",
              fqdn: "new.org",
              org_dn: "new"
            }
          }
    institution.reload
    assert_equal "New Institution", institution.name
  end

  test "update() returns HTTP 200" do
    user = users(:uiuc_admin)
    log_in_as(user)
    institution = user.institution
    patch institution_path(institution),
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

  test "update() returns HTTP 400 for illegal arguments" do
    log_in_as(users(:local_sysadmin))
    institution = institutions(:somewhere)
    patch institution_path(institution),
          xhr: true,
          params: {
            institution: {
              name: "" # invalid
            }
          }
    assert_response :bad_request
  end

  test "update() returns HTTP 404 for nonexistent institutions" do
    log_in_as(users(:local_sysadmin))
    patch "/institutions/bogus"
    assert_response :not_found
  end

end
