require 'test_helper'

class EventsControllerTest < ActionDispatch::IntegrationTest

  setup do
    @institution = institutions(:southwest)
    host! @institution.fqdn
  end

  teardown do
    log_out
  end

  # index()

  test "index() returns HTTP 404 for unscoped requests" do
    host! ::Configuration.instance.main_host
    get events_path
    assert_response :not_found
  end

  test "index() redirects to root page for logged-out users" do
    get events_path
    assert_redirected_to @institution.scope_url
  end

  test "index() returns HTTP 403 for unauthorized users" do
    log_in_as(users(:southwest))
    get events_path
    assert_response :forbidden
  end

  test "index() returns HTTP 200 for authorized users" do
    log_in_as(users(:southwest_admin))
    get events_path
    assert_response :ok
  end

  test "index() respects role limits" do
    log_in_as(users(:southwest_admin))
    get events_path
    assert_response :ok

    get events_path(role: Role::LOGGED_OUT)
    assert_response :forbidden
  end

  # index_all()

  test "index_all() returns HTTP 404 for unscoped requests" do
    host! ::Configuration.instance.main_host
    get all_events_path
    assert_response :not_found
  end

  test "index_all() redirects to root page for logged-out users" do
    get all_events_path
    assert_redirected_to @institution.scope_url
  end

  test "index_all() returns HTTP 403 for unauthorized users" do
    log_in_as(users(:southwest_admin))
    get all_events_path
    assert_response :forbidden
  end

  test "index_all() returns HTTP 200 for authorized users" do
    log_in_as(users(:southwest_sysadmin))
    get all_events_path
    assert_response :ok
  end

  test "index_all() respects role limits" do
    log_in_as(users(:southwest_sysadmin))
    get all_events_path
    assert_response :ok

    get all_events_path(role: Role::LOGGED_OUT)
    assert_response :forbidden
  end

  # show()

  test "show() returns HTTP 404 for unscoped requests" do
    host! ::Configuration.instance.main_host
    get event_path(events(:southwest_item1_create)), xhr: true
    assert_response :not_found
  end

  test "show() returns HTTP 403 for logged-out users" do
    get event_path(events(:southwest_item1_create)), xhr: true
    assert_response :forbidden
  end

  test "show() returns HTTP 403 for unauthorized users" do
    log_in_as(users(:southwest))
    get event_path(events(:southwest_item1_create)), xhr: true
    assert_response :forbidden
  end

  test "show() returns HTTP 200 for authorized users" do
    log_in_as(users(:southwest_sysadmin))
    get event_path(events(:southwest_item1_create)), xhr: true
    assert_response :ok
  end

  test "show() respects role limits" do
    log_in_as(users(:southwest_sysadmin))
    get event_path(events(:southwest_item1_create)), xhr: true
    assert_response :ok

    get event_path(events(:southwest_item1_create),
                  role: Role::LOGGED_OUT)
    assert_response :forbidden
  end

end
