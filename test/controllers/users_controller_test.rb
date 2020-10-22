require 'test_helper'

class UsersControllerTest < ActionDispatch::IntegrationTest

  setup do
    setup_elasticsearch
  end

  teardown do
    log_out
  end

  # edit_privileges()

  test "edit_privileges() redirects to login page for logged-out users" do
    get user_edit_privileges_path(users(:admin)), xhr: true
    assert_redirected_to login_path
  end

  test "edit_privileges() returns HTTP 403 for unauthorized users" do
    log_in_as(users(:norights))
    get user_edit_privileges_path(users(:admin)), xhr: true
    assert_response :forbidden
  end

  test "edit_privileges() returns HTTP 200 for authorized users" do
    log_in_as(users(:admin))
    get user_edit_privileges_path(users(:admin)), xhr: true
    assert_response :ok
  end

  test "edit_privileges() respects role limits" do
    log_in_as(users(:admin))
    get user_edit_privileges_path(users(:admin)), xhr: true
    assert_response :ok

    get user_edit_privileges_path(users(:admin),
                                  role: Role::LOGGED_IN), xhr: true
    assert_response :forbidden
  end

  # edit_properties()

  test "edit_properties() redirects to login page for logged-out users" do
    get user_edit_properties_path(users(:admin)), xhr: true
    assert_redirected_to login_path
  end

  test "edit_properties() returns HTTP 403 for unauthorized users" do
    log_in_as(users(:norights))
    get user_edit_properties_path(users(:admin)), xhr: true
    assert_response :forbidden
  end

  test "edit_properties() returns HTTP 200 for authorized users" do
    log_in_as(users(:admin))
    get user_edit_properties_path(users(:admin)), xhr: true
    assert_response :ok
  end

  test "edit_properties() respects role limits" do
    log_in_as(users(:admin))
    get user_edit_properties_path(users(:admin)), xhr: true
    assert_response :ok

    get user_edit_properties_path(users(:admin),
                                  role: Role::LOGGED_OUT), xhr: true
    assert_response :forbidden
  end

  # index()

  test "index() redirects to login page for logged-out users" do
    get users_path
    assert_redirected_to login_path
  end

  test "index() returns HTTP 403 for unauthorized users" do
    log_in_as(users(:norights))
    get users_path
    assert_response :forbidden
  end

  test "index() returns HTTP 200 for authorized users for HTML" do
    log_in_as(users(:admin))
    get users_path
    assert_response :ok
  end

  test "index() returns HTTP 200 for authorized users for JSON" do
    log_in_as(users(:admin))
    get users_path(format: :json)
    assert_response :ok
  end

  test "index() respects role limits" do
    log_in_as(users(:admin))
    get users_path
    assert_response :ok

    get users_path(role: Role::LOGGED_OUT)
    assert_response :forbidden
  end

  # show()

  test "show() redirects to login page for logged-out users" do
    get user_path(users(:admin))
    assert_redirected_to login_path
  end

  test "show() returns HTTP 403 for unauthorized users" do
    log_in_as(users(:norights))
    get user_path(users(:admin))
    assert_response :forbidden
  end

  test "show() returns HTTP 200 for authorized users" do
    log_in_as(users(:admin))
    get user_path(users(:admin))
    assert_response :ok
  end

  test "show() respects role limits" do
    log_in_as(users(:admin))
    get user_path(users(:admin))
    assert_response :ok

    get user_path(users(:admin), role: Role::LOGGED_OUT)
    assert_response :forbidden
  end

  # update_privileges()

  test "update_privileges() redirects to login page for logged-out users" do
    user = users(:admin)
    patch user_update_privileges_path(user), xhr: true
    assert_redirected_to login_path
  end

  test "update_privileges() returns HTTP 403 for unauthorized users" do
    log_in_as(users(:norights))
    user = users(:admin)
    patch user_update_privileges_path(user), xhr: true
    assert_response :forbidden
  end

  test "update_privileges() updates a user" do
    log_in_as(users(:admin))
    user = users(:norights)
    patch user_update_privileges_path(user),
          xhr: true,
          params: {
              user: {
                  user_group_ids: [user_groups(:unused).id]
              }
          }
    user.reload
    assert_equal [user_groups(:unused)], user.user_groups
  end

  test "update_privileges() returns HTTP 200" do
    log_in_as(users(:admin))
    user = users(:admin)
    patch user_update_privileges_path(user),
          xhr: true,
          params: {
              user: {
                  user_group_ids: [user_groups(:unused).id]
              }
          }
    assert_response :ok
  end

  test "update_privileges() returns HTTP 400 for illegal arguments" do
    log_in_as(users(:admin))
    user = users(:admin)
    patch user_update_privileges_path(user),
          xhr: true,
          params: {
              user_group_ids: [999999]
          }
    assert_response :bad_request
  end

  test "update_privileges() returns HTTP 404 for nonexistent users" do
    log_in_as(users(:admin))
    patch "/users/99999999/update-privileges", xhr: true
    assert_response :not_found
  end

  # update_properties()

  test "update_properties() redirects to login page for logged-out users" do
    user = users(:admin)
    patch user_update_properties_path(user), xhr: true
    assert_redirected_to login_path
  end

  test "update_properties() returns HTTP 403 for unauthorized users" do
    log_in_as(users(:norights))
    user = users(:admin)
    patch user_update_properties_path(user), xhr: true
    assert_response :forbidden
  end

  test "update_properties() updates a user" do
    log_in_as(users(:admin))
    user = users(:norights)
    patch user_update_properties_path(user),
          xhr: true,
          params: {
              user: {
                  phone: "555-5155"
              }
          }
    user.reload
    assert_equal "555-5155", user.phone
  end

  test "update_properties() returns HTTP 200" do
    log_in_as(users(:admin))
    user = users(:admin)
    patch user_update_properties_path(user),
          xhr: true,
          params: {
              user: {
                  sysadmin: true
              }
          }
    assert_response :ok
  end

  test "update_properties() returns HTTP 400 for illegal arguments" do
    log_in_as(users(:admin))
    user = users(:admin)
    patch user_update_properties_path(user),
          xhr: true,
          params: {
              user: {
                  email: ""
              }
          }
    assert_response :bad_request
  end

  test "update_properties() returns HTTP 404 for nonexistent users" do
    log_in_as(users(:admin))
    patch "/users/99999999/update-properties", xhr: true
    assert_response :not_found
  end

end
