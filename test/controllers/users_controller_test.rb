require 'test_helper'

class UsersControllerTest < ActionDispatch::IntegrationTest

  setup do
    setup_elasticsearch
  end

  teardown do
    log_out
  end

  # edit_properties()

  test "edit_properties() redirects to login page for logged-out users" do
    get user_edit_properties_path(users(:local_sysadmin)), xhr: true
    assert_redirected_to login_path
  end

  test "edit_properties() returns HTTP 403 for unauthorized users" do
    log_in_as(users(:norights))
    get user_edit_properties_path(users(:local_sysadmin)), xhr: true
    assert_response :forbidden
  end

  test "edit_properties() returns HTTP 200 for authorized users" do
    log_in_as(users(:local_sysadmin))
    get user_edit_properties_path(users(:local_sysadmin)), xhr: true
    assert_response :ok
  end

  test "edit_properties() respects role limits" do
    log_in_as(users(:local_sysadmin))
    get user_edit_properties_path(users(:local_sysadmin)), xhr: true
    assert_response :ok

    get user_edit_properties_path(users(:local_sysadmin),
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
    log_in_as(users(:local_sysadmin))
    get users_path
    assert_response :ok
  end

  test "index() returns HTTP 200 for authorized users for JSON" do
    log_in_as(users(:local_sysadmin))
    get users_path(format: :json)
    assert_response :ok
  end

  test "index() respects role limits" do
    log_in_as(users(:local_sysadmin))
    get users_path
    assert_response :ok

    get users_path(role: Role::LOGGED_OUT)
    assert_response :forbidden
  end

  # show()

  test "show() redirects to login page for logged-out users" do
    get user_path(users(:local_sysadmin))
    assert_redirected_to login_path
  end

  test "show() returns HTTP 403 for unauthorized users" do
    log_in_as(users(:norights))
    get user_path(users(:local_sysadmin))
    assert_response :forbidden
  end

  test "show() returns HTTP 200 for authorized users" do
    log_in_as(users(:local_sysadmin))
    get user_path(users(:local_sysadmin))
    assert_response :ok
  end

  test "show() respects role limits" do
    log_in_as(users(:local_sysadmin))
    get user_path(users(:local_sysadmin))
    assert_response :ok

    get user_path(users(:local_sysadmin), role: Role::LOGGED_OUT)
    assert_response :forbidden
  end

  # show_properties()

  test "show_properties() redirects to login page for logged-out users" do
    get user_properties_path(users(:local_sysadmin)), xhr: true
    assert_redirected_to login_path
  end

  test "show_properties() returns HTTP 403 for unauthorized users" do
    log_in_as(users(:norights))
    get user_properties_path(users(:local_sysadmin)), xhr: true
    assert_response :forbidden
  end

  test "show_properties() returns HTTP 404 for non-XHR requests" do
    log_in_as(users(:norights))
    get user_properties_path(users(:local_sysadmin))
    assert_response :not_found
  end

  test "show_properties() returns HTTP 200 for authorized users" do
    log_in_as(users(:local_sysadmin))
    get user_properties_path(users(:local_sysadmin)), xhr: true
    assert_response :ok
  end

  test "show_properties() respects role limits" do
    log_in_as(users(:local_sysadmin))
    get user_properties_path(users(:local_sysadmin)), xhr: true
    assert_response :ok

    get user_properties_path(users(:local_sysadmin), role: Role::LOGGED_OUT), xhr: true
    assert_response :forbidden
  end

  # show_submittable_collections()

  test "show_submittable_collections() redirects to login page for logged-out users" do
    get user_submittable_collections_path(users(:local_sysadmin)), xhr: true
    assert_redirected_to login_path
  end

  test "show_submittable_collections() returns HTTP 403 for unauthorized users" do
    log_in_as(users(:norights))
    get user_submittable_collections_path(users(:local_sysadmin)), xhr: true
    assert_response :forbidden
  end

  test "show_submittable_collections() returns HTTP 404 for non-XHR requests" do
    log_in_as(users(:norights))
    get user_submittable_collections_path(users(:local_sysadmin))
    assert_response :not_found
  end

  test "show_submittable_collections() returns HTTP 200 for authorized users" do
    log_in_as(users(:local_sysadmin))
    get user_submittable_collections_path(users(:local_sysadmin)), xhr: true
    assert_response :ok
  end

  test "show_submittable_collections() respects role limits" do
    log_in_as(users(:local_sysadmin))
    get user_submittable_collections_path(users(:local_sysadmin)), xhr: true
    assert_response :ok

    get user_submittable_collections_path(users(:local_sysadmin), role: Role::LOGGED_OUT), xhr: true
    assert_response :forbidden
  end

  # show_submitted_items()

  test "show_submitted_items() redirects to login page for logged-out users" do
    get user_submitted_items_path(users(:local_sysadmin)), xhr: true
    assert_redirected_to login_path
  end

  test "show_submitted_items() returns HTTP 403 for unauthorized users" do
    log_in_as(users(:norights))
    get user_submitted_items_path(users(:local_sysadmin)), xhr: true
    assert_response :forbidden
  end

  test "show_submitted_items() returns HTTP 404 for non-XHR requests" do
    log_in_as(users(:norights))
    get user_submitted_items_path(users(:local_sysadmin))
    assert_response :not_found
  end

  test "show_submitted_items() returns HTTP 200 for authorized users" do
    log_in_as(users(:local_sysadmin))
    get user_submitted_items_path(users(:local_sysadmin)), xhr: true
    assert_response :ok
  end

  test "show_submitted_items() respects role limits" do
    log_in_as(users(:local_sysadmin))
    get user_submitted_items_path(users(:local_sysadmin)), xhr: true
    assert_response :ok

    get user_submitted_items_path(users(:local_sysadmin), role: Role::LOGGED_OUT), xhr: true
    assert_response :forbidden
  end

  # show_submissions_in_progress()

  test "show_submissions_in_progress() redirects to login page for logged-out users" do
    get user_submissions_in_progress_path(users(:local_sysadmin)), xhr: true
    assert_redirected_to login_path
  end

  test "show_submissions_in_progress() returns HTTP 403 for unauthorized users" do
    log_in_as(users(:norights))
    get user_submissions_in_progress_path(users(:local_sysadmin)), xhr: true
    assert_response :forbidden
  end

  test "show_submissions_in_progress() returns HTTP 404 for non-XHR requests" do
    log_in_as(users(:norights))
    get user_submissions_in_progress_path(users(:local_sysadmin))
    assert_response :not_found
  end

  test "show_submissions_in_progress() returns HTTP 200 for authorized users" do
    log_in_as(users(:local_sysadmin))
    get user_submissions_in_progress_path(users(:local_sysadmin)), xhr: true
    assert_response :ok
  end

  test "show_submissions_in_progress() respects role limits" do
    log_in_as(users(:local_sysadmin))
    get user_submissions_in_progress_path(users(:local_sysadmin)), xhr: true
    assert_response :ok

    get user_submissions_in_progress_path(users(:local_sysadmin), role: Role::LOGGED_OUT), xhr: true
    assert_response :forbidden
  end

  # submitted_item_results()

  test "submitted_item_results() redirects to login page for logged-out users" do
    get user_submitted_item_results_path(users(:local_sysadmin)), xhr: true
    assert_redirected_to login_path
  end

  test "submitted_item_results() returns HTTP 403 for unauthorized users" do
    log_in_as(users(:norights))
    get user_submitted_item_results_path(users(:local_sysadmin)), xhr: true
    assert_response :forbidden
  end

  test "submitted_item_results() returns HTTP 404 for non-XHR requests" do
    log_in_as(users(:norights))
    get user_submitted_item_results_path(users(:local_sysadmin))
    assert_response :not_found
  end

  test "submitted_item_results() returns HTTP 200 for authorized users" do
    log_in_as(users(:local_sysadmin))
    get user_submitted_item_results_path(users(:local_sysadmin)), xhr: true
    assert_response :ok
  end

  test "submitted_item_results() respects role limits" do
    log_in_as(users(:local_sysadmin))
    get user_submitted_item_results_path(users(:local_sysadmin)), xhr: true
    assert_response :ok

    get user_submitted_item_results_path(users(:local_sysadmin), role: Role::LOGGED_OUT), xhr: true
    assert_response :forbidden
  end

  # update_properties()

  test "update_properties() redirects to login page for logged-out users" do
    user = users(:local_sysadmin)
    patch user_update_properties_path(user), xhr: true
    assert_redirected_to login_path
  end

  test "update_properties() returns HTTP 403 for unauthorized users" do
    log_in_as(users(:norights))
    user = users(:local_sysadmin)
    patch user_update_properties_path(user), xhr: true
    assert_response :forbidden
  end

  test "update_properties() updates a user" do
    log_in_as(users(:local_sysadmin))
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
    log_in_as(users(:local_sysadmin))
    user = users(:local_sysadmin)
    patch user_update_properties_path(user),
          xhr: true,
          params: {
              user: {
                  phone: "555-5155"
              }
          }
    assert_response :ok
  end

  test "update_properties() returns HTTP 400 for illegal arguments" do
    log_in_as(users(:local_sysadmin))
    user = users(:local_sysadmin)
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
    log_in_as(users(:local_sysadmin))
    patch "/users/99999999/update-properties", xhr: true
    assert_response :not_found
  end

end
