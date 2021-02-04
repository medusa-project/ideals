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
             org_dn: "new"
           }
         }
    assert_response :forbidden
  end

  test "create() returns HTTP 200 for authorized users" do
    log_in_as(users(:shibboleth_admin))
    post institutions_path,
         xhr: true,
         params: {
           institution: {
             name: "New Institution",
             key: "new",
             org_dn: "new"
           }
         }
    assert_response :ok
  end

  test "create() creates an institution" do
    user = users(:shibboleth_admin)
    log_in_as(user)
    assert_difference "Institution.count" do
      post institutions_path,
           xhr: true,
           params: {
             institution: {
               name: "New Institution",
               key: "new",
               org_dn: "new"
             }
           }
    end
  end

  test "create() returns HTTP 400 for illegal arguments" do
    log_in_as(users(:admin))
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
    log_in_as(users(:admin))
    institution = institutions(:empty)
    delete institution_path(institution)
    assert_raises ActiveRecord::RecordNotFound do
      Institution.find(institution.id)
    end
  end

  test "destroy() returns HTTP 302 for an existing institution" do
    log_in_as(users(:admin))
    institution = institutions(:somewhere)
    delete institution_path(institution)
    assert_redirected_to institutions_path
  end

  test "destroy() returns HTTP 404 for a missing institution" do
    log_in_as(users(:admin))
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
    log_in_as(users(:admin))
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
    log_in_as(users(:shibboleth_admin))
    get institutions_path
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
    log_in_as(users(:shibboleth_admin))
    get new_institution_path
    assert_response :ok
  end

  # show()

  test "show() redirects to login page for logged-out users" do
    get institution_path(institutions(:somewhere))
    assert_redirected_to login_path
  end

  test "show() returns HTTP 403 for unauthorized users" do
    log_in_as(users(:shibboleth))
    get institution_path(institutions(:somewhere))
    assert_response :forbidden
  end

  test "show() returns HTTP 200 for authorized users" do
    log_in_as(users(:shibboleth_admin))
    get institution_path(institutions(:somewhere))
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
    log_in_as(users(:admin))
    institution = institutions(:somewhere)
    patch institution_path(institution),
          xhr: true,
          params: {
            institution: {
              name: "New Institution",
              key: "new",
              org_dn: "new"
            }
          }
    institution.reload
    assert_equal "New Institution", institution.name
  end

  test "update() returns HTTP 200" do
    log_in_as(users(:admin))
    institution = institutions(:somewhere)
    patch institution_path(institution),
          xhr: true,
          params: {
            institution: {
              name: "New Institution",
              key: "new",
              org_dn: "new"
            }
          }
    assert_response :ok
  end

  test "update() returns HTTP 400 for illegal arguments" do
    log_in_as(users(:admin))
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
    log_in_as(users(:admin))
    patch "/institutions/bogus"
    assert_response :not_found
  end

end
