require 'test_helper'

class UsersControllerTest < ActionDispatch::IntegrationTest

  setup do
    @institution = institutions(:southwest)
    host! @institution.fqdn
    setup_opensearch
  end

  teardown do
    log_out
  end

  # edit_properties()

  test "edit_properties() returns HTTP 404 for unscoped requests" do
    host! ::Configuration.instance.main_host
    get user_edit_properties_path(users(:southwest)), xhr: true
    assert_response :not_found
  end

  test "edit_properties() returns HTTP 403 for logged-out users" do
    get user_edit_properties_path(users(:southwest)), xhr: true
    assert_response :forbidden
  end

  test "edit_properties() returns HTTP 403 for unauthorized users" do
    log_in_as(users(:southwest))
    get user_edit_properties_path(users(:southwest_admin)), xhr: true
    assert_response :forbidden
  end

  test "edit_properties() returns HTTP 200 for authorized users" do
    user = users(:southwest_admin)
    log_in_as(user)
    get user_edit_properties_path(user), xhr: true
    assert_response :ok
  end

  test "edit_properties() respects role limits" do
    user = users(:southwest_admin)
    log_in_as(user)
    get user_edit_properties_path(user), xhr: true
    assert_response :ok

    get user_edit_properties_path(user, role: Role::LOGGED_OUT), xhr: true
    assert_response :forbidden
  end

  # disable()

  test "disable() returns HTTP 404 for unscoped requests" do
    host! ::Configuration.instance.main_host
    patch user_disable_path(users(:southwest))
    assert_response :not_found
  end

  test "disable() redirects to root page for logged-out users" do
    patch user_disable_path(users(:southwest))
    assert_redirected_to @institution.scope_url
  end

  test "disable() returns HTTP 403 for unauthorized users" do
    log_in_as(users(:southwest))
    patch user_disable_path(users(:southwest_admin))
    assert_response :forbidden
  end

  test "disable() redirects to the show-user page for authorized users" do
    log_in_as(users(:southwest_admin))
    user = users(:southwest)
    patch user_disable_path(user)
    assert_redirected_to user_path(user)
  end

  test "disable() respects role limits" do
    log_in_as(users(:southwest_admin))
    user = users(:southwest)
    patch user_disable_path(user)
    assert_redirected_to user_path(user)

    patch user_disable_path(user, role: Role::LOGGED_OUT)
    assert_response :forbidden
  end

  # enable()

  test "enable() returns HTTP 404 for unscoped requests" do
    host! ::Configuration.instance.main_host
    patch user_enable_path(users(:southwest))
    assert_response :not_found
  end

  test "enable() redirects to root page for logged-out users" do
    patch user_enable_path(users(:southwest))
    assert_redirected_to @institution.scope_url
  end

  test "enable() returns HTTP 403 for unauthorized users" do
    log_in_as(users(:southwest))
    patch user_enable_path(users(:southwest_admin))
    assert_response :forbidden
  end

  test "enable() redirects to the show-user page for authorized users" do
    log_in_as(users(:southwest_admin))
    user = users(:southwest)
    patch user_enable_path(user)
    assert_redirected_to user_path(users(:southwest))
  end

  test "enable() respects role limits" do
    log_in_as(users(:southwest_admin))
    user = users(:southwest)
    patch user_enable_path(user)
    assert_redirected_to user_path(user)

    patch user_enable_path(user, role: Role::LOGGED_OUT)
    assert_response :forbidden
  end

  # index()

  test "index() returns HTTP 404 for unscoped requests" do
    host! ::Configuration.instance.main_host
    get users_path
    assert_response :not_found
  end

  test "index() redirects to root page for logged-out users" do
    get users_path
    assert_redirected_to @institution.scope_url
  end

  test "index() returns HTTP 403 for unauthorized users" do
    log_in_as(users(:southwest))
    get users_path
    assert_response :forbidden
  end

  test "index() returns HTTP 200 for authorized users for HTML" do
    log_in_as(users(:southwest_admin))
    get users_path
    assert_response :ok
  end

  test "index() returns HTTP 200 for authorized users for JSON" do
    log_in_as(users(:southwest_admin))
    get users_path(format: :json)
    assert_response :ok
  end

  test "index() respects role limits" do
    log_in_as(users(:southwest_admin))
    get users_path
    assert_response :ok

    get users_path(role: Role::LOGGED_OUT)
    assert_response :forbidden
  end

  # index_all()

  test "index_all() returns HTTP 404 for unscoped requests" do
    host! ::Configuration.instance.main_host
    get all_users_path
    assert_response :not_found
  end

  test "index_all() redirects to root page for logged-out users" do
    get all_users_path
    assert_redirected_to @institution.scope_url
  end

  test "index_all() returns HTTP 403 for unauthorized users" do
    log_in_as(users(:southwest))
    get all_users_path
    assert_response :forbidden
  end

  test "index_all() returns HTTP 200 for authorized users for HTML" do
    log_in_as(users(:southwest_sysadmin))
    get all_users_path
    assert_response :ok
  end

  test "index_all() returns HTTP 200 for authorized users for JSON" do
    log_in_as(users(:southwest_sysadmin))
    get all_users_path(format: :json)
    assert_response :ok
  end

  test "index_all() respects role limits" do
    log_in_as(users(:southwest_sysadmin))
    get all_users_path
    assert_response :ok

    get all_users_path(role: Role::LOGGED_OUT)
    assert_response :forbidden
  end

  # show()

  test "show() returns HTTP 404 for unscoped requests" do
    host! ::Configuration.instance.main_host
    get user_path(users(:southwest))
    assert_response :not_found
  end

  test "show() redirects to root page for logged-out users" do
    get user_path(users(:southwest))
    assert_redirected_to @institution.scope_url
  end

  test "show() returns HTTP 403 for unauthorized users" do
    log_in_as(users(:southwest))
    get user_path(users(:southwest_admin))
    assert_response :forbidden
  end

  test "show() returns HTTP 200 for authorized users" do
    user = users(:southwest)
    log_in_as(user)
    get user_path(user)
    assert_response :ok
  end

  test "show() respects role limits" do
    user = users(:southwest_admin)
    log_in_as(user)
    get user_path(user)
    assert_response :ok

    get user_path(user, role: Role::LOGGED_OUT)
    assert_response :forbidden
  end

  # show_credentials()

  test "show_credentials() returns HTTP 404 for unscoped requests" do
    host! ::Configuration.instance.main_host
    get user_credentials_path(users(:southwest)), xhr: true
    assert_response :not_found
  end

  test "show_credentials() returns HTTP 403 for logged-out users" do
    get user_credentials_path(users(:southwest)), xhr: true
    assert_response :forbidden
  end

  test "show_credentials() returns HTTP 403 for unauthorized users" do
    log_in_as(users(:southwest))
    get user_credentials_path(users(:southwest_admin)), xhr: true
    assert_response :forbidden
  end

  test "show_credentials() returns HTTP 404 for non-XHR requests" do
    log_in_as(users(:southwest))
    get user_credentials_path(users(:southwest))
    assert_response :not_found
  end

  test "show_credentials() returns HTTP 200 for authorized users" do
    log_in_as(users(:southwest_admin))
    get user_credentials_path(users(:southwest)), xhr: true
    assert_response :ok
  end

  test "show_credentials() respects role limits" do
    user = users(:southwest)
    log_in_as(user)
    get user_credentials_path(user), xhr: true
    assert_response :ok

    get user_credentials_path(user, role: Role::LOGGED_OUT), xhr: true
    assert_response :forbidden
  end

  # show_logins()

  test "show_logins() returns HTTP 404 for unscoped requests" do
    host! ::Configuration.instance.main_host
    get user_logins_path(users(:southwest)), xhr: true
    assert_response :not_found
  end

  test "show_logins() returns HTTP 403 for logged-out users" do
    get user_logins_path(users(:southwest)), xhr: true
    assert_response :forbidden
  end

  test "show_logins() returns HTTP 403 for unauthorized users" do
    log_in_as(users(:southwest))
    get user_logins_path(users(:southwest_admin)), xhr: true
    assert_response :forbidden
  end

  test "show_logins() returns HTTP 404 for non-XHR requests" do
    log_in_as(users(:southwest))
    get user_logins_path(users(:southwest))
    assert_response :not_found
  end

  test "show_logins() returns HTTP 200 for authorized users" do
    log_in_as(users(:southwest_admin))
    get user_logins_path(users(:southwest)), xhr: true
    assert_response :ok
  end

  test "show_logins() respects role limits" do
    user = users(:southwest)
    log_in_as(user)
    get user_logins_path(user), xhr: true
    assert_response :ok

    get user_logins_path(user, role: Role::LOGGED_OUT), xhr: true
    assert_response :forbidden
  end

  # show_properties()

  test "show_properties() returns HTTP 404 for unscoped requests" do
    host! ::Configuration.instance.main_host
    get user_properties_path(users(:southwest)), xhr: true
    assert_response :not_found
  end

  test "show_properties() returns HTTP 403 for logged-out users" do
    get user_properties_path(users(:southwest)), xhr: true
    assert_response :forbidden
  end

  test "show_properties() returns HTTP 403 for unauthorized users" do
    log_in_as(users(:southwest))
    get user_properties_path(users(:southwest_admin)), xhr: true
    assert_response :forbidden
  end

  test "show_properties() returns HTTP 404 for non-XHR requests" do
    log_in_as(users(:southwest))
    get user_properties_path(users(:southwest))
    assert_response :not_found
  end

  test "show_properties() returns HTTP 200 for authorized users" do
    log_in_as(users(:southwest_admin))
    get user_properties_path(users(:southwest)), xhr: true
    assert_response :ok
  end

  test "show_properties() respects role limits" do
    user = users(:southwest)
    log_in_as(user)
    get user_properties_path(user), xhr: true
    assert_response :ok

    get user_properties_path(user, role: Role::LOGGED_OUT), xhr: true
    assert_response :forbidden
  end

  # show_submittable_collections()

  test "show_submittable_collections() returns HTTP 404 for unscoped requests" do
    host! ::Configuration.instance.main_host
    get user_submittable_collections_path(users(:southwest)), xhr: true
    assert_response :not_found
  end

  test "show_submittable_collections() returns HTTP 403 for logged-out users" do
    get user_submittable_collections_path(users(:southwest)), xhr: true
    assert_response :forbidden
  end

  test "show_submittable_collections() returns HTTP 403 for unauthorized users" do
    log_in_as(users(:southwest))
    get user_submittable_collections_path(users(:southwest_admin)), xhr: true
    assert_response :forbidden
  end

  test "show_submittable_collections() returns HTTP 404 for non-XHR requests" do
    log_in_as(users(:southwest))
    get user_submittable_collections_path(users(:southwest))
    assert_response :not_found
  end

  test "show_submittable_collections() returns HTTP 200 for authorized users" do
    log_in_as(users(:southwest_admin))
    get user_submittable_collections_path(users(:southwest)), xhr: true
    assert_response :ok
  end

  test "show_submittable_collections() returns JSON" do
    log_in_as(users(:southwest_admin))
    get user_submittable_collections_path(users(:southwest_admin), format: :json), xhr: true
    assert_response :ok
    struct = JSON.parse(response.body)
    assert struct['results'].length > 0
  end

  test "show_submittable_collections() respects role limits" do
    log_in_as(users(:southwest_admin))
    user = users(:southwest)
    get user_submittable_collections_path(user), xhr: true
    assert_response :ok

    get user_submittable_collections_path(user, role: Role::LOGGED_OUT), xhr: true
    assert_response :forbidden
  end

  # show_submitted_items()

  test "show_submitted_items() returns HTTP 404 for unscoped requests" do
    host! ::Configuration.instance.main_host
    get user_submitted_items_path(users(:southwest)), xhr: true
    assert_response :not_found
  end

  test "show_submitted_items() returns HTTP 403 for logged-out users" do
    get user_submitted_items_path(users(:southwest)), xhr: true
    assert_response :forbidden
  end

  test "show_submitted_items() returns HTTP 403 for unauthorized users" do
    log_in_as(users(:southwest))
    get user_submitted_items_path(users(:southwest_admin)), xhr: true
    assert_response :forbidden
  end

  test "show_submitted_items() returns HTTP 404 for non-XHR requests" do
    user = users(:southwest)
    log_in_as(user)
    get user_submitted_items_path(user)
    assert_response :not_found
  end

  test "show_submitted_items() returns HTTP 200 for authorized users" do
    user = users(:southwest)
    log_in_as(user)
    get user_submitted_items_path(user), xhr: true
    assert_response :ok
  end

  test "show_submitted_items() respects role limits" do
    log_in_as(users(:southwest_admin))
    user = users(:southwest)
    get user_submitted_items_path(user), xhr: true
    assert_response :ok

    get user_submitted_items_path(user, role: Role::LOGGED_OUT), xhr: true
    assert_response :forbidden
  end

  # show_submissions_in_progress()

  test "show_submissions_in_progress() returns HTTP 404 for unscoped requests" do
    host! ::Configuration.instance.main_host
    get user_submissions_in_progress_path(users(:southwest)), xhr: true
    assert_response :not_found
  end

  test "show_submissions_in_progress() returns HTTP 403 for logged-out users" do
    get user_submissions_in_progress_path(users(:southwest)), xhr: true
    assert_response :forbidden
  end

  test "show_submissions_in_progress() returns HTTP 403 for unauthorized users" do
    log_in_as(users(:southwest))
    get user_submissions_in_progress_path(users(:southwest_admin)), xhr: true
    assert_response :forbidden
  end

  test "show_submissions_in_progress() returns HTTP 404 for non-XHR requests" do
    log_in_as(users(:southwest))
    get user_submissions_in_progress_path(users(:southwest))
    assert_response :not_found
  end

  test "show_submissions_in_progress() returns HTTP 200 for authorized users" do
    log_in_as(users(:southwest))
    get user_submissions_in_progress_path(users(:southwest)), xhr: true
    assert_response :ok
  end

  test "show_submissions_in_progress() respects role limits" do
    log_in_as(users(:southwest_admin))
    user = users(:southwest)
    get user_submissions_in_progress_path(user), xhr: true
    assert_response :ok

    get user_submissions_in_progress_path(user, role: Role::LOGGED_OUT), xhr: true
    assert_response :forbidden
  end

  # submitted_item_results()

  test "submitted_item_results() returns HTTP 404 for unscoped requests" do
    host! ::Configuration.instance.main_host
    get user_submitted_item_results_path(users(:southwest)), xhr: true
    assert_response :not_found
  end

  test "submitted_item_results() returns HTTP 403 for logged-out users" do
    get user_submitted_item_results_path(users(:southwest)), xhr: true
    assert_response :forbidden
  end

  test "submitted_item_results() returns HTTP 403 for unauthorized users" do
    log_in_as(users(:southwest))
    get user_submitted_item_results_path(users(:southwest_admin)), xhr: true
    assert_response :forbidden
  end

  test "submitted_item_results() returns HTTP 404 for non-XHR requests" do
    log_in_as(users(:southwest))
    get user_submitted_item_results_path(users(:southwest))
    assert_response :not_found
  end

  test "submitted_item_results() returns HTTP 200 for authorized users" do
    log_in_as(users(:southwest))
    get user_submitted_item_results_path(users(:southwest)), xhr: true
    assert_response :ok
  end

  test "submitted_item_results() respects role limits" do
    log_in_as(users(:southwest_admin))
    user = users(:southwest)
    get user_submitted_item_results_path(user), xhr: true
    assert_response :ok

    get user_submitted_item_results_path(user, role: Role::LOGGED_OUT), xhr: true
    assert_response :forbidden
  end

  # update_properties()

  test "update_properties() returns HTTP 404 for unscoped requests" do
    host! ::Configuration.instance.main_host
    patch user_update_properties_path(users(:southwest)), xhr: true
    assert_response :not_found
  end

  test "update_properties() returns HTTP 403 for logged-out users" do
    patch user_update_properties_path(users(:southwest)), xhr: true
    assert_response :forbidden
  end

  test "update_properties() returns HTTP 403 for unauthorized users" do
    log_in_as(users(:southwest))
    patch user_update_properties_path(users(:southwest_admin)), xhr: true
    assert_response :forbidden
  end

  test "update_properties() updates a user" do
    user = users(:southwest)
    log_in_as(user)
    patch user_update_properties_path(user),
          xhr: true,
          params: {
            user: {
              name: "New Name"
            }
          }
    user.reload
    assert_equal "New Name", user.name
  end

  test "update_properties() returns HTTP 200" do
    user = users(:southwest_admin)
    log_in_as(user)
    patch user_update_properties_path(user),
          xhr: true,
          params: {
            user: {
              name: "New Name"
            }
          }
    assert_response :ok
  end

  test "update_properties() returns HTTP 400 for illegal arguments" do
    user = users(:southwest_admin)
    log_in_as(user)
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
    log_in_as(users(:southwest_admin))
    patch "/users/99999999/update-properties", xhr: true
    assert_response :not_found
  end

end
