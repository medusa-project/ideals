require 'test_helper'

class StatisticsControllerTest < ActionDispatch::IntegrationTest

  setup do
    @institution = institutions(:southwest)
    host! @institution.fqdn
  end

  teardown do
    log_out
  end

  # files()

  test "files() returns HTTP 403 for logged-out users" do
    get statistics_files_path, xhr: true
    assert_response :forbidden
  end

  test "files() returns HTTP 403 for unauthorized users" do
    log_in_as(users(:southwest))
    get statistics_files_path, xhr: true
    assert_response :forbidden
  end

  test "files() returns HTTP 200 for authorized users" do
    log_in_as(users(:southwest_sysadmin))
    get statistics_files_path, xhr: true
    assert_response :ok
  end

  test "files() returns HTTP 404 for non-XHR requests" do
    log_in_as(users(:southwest_sysadmin))
    get statistics_files_path
    assert_response :not_found
  end

  test "files() respects role limits" do
    log_in_as(users(:southwest_sysadmin))
    get statistics_files_path, xhr: true
    assert_response :ok

    get statistics_files_path(role: Role::LOGGED_OUT), xhr: true
    assert_response :forbidden
  end

  # index()

  test "index() redirects to root page for logged-out users" do
    get statistics_path
    assert_redirected_to @institution.scope_url
  end

  test "index() returns HTTP 403 for unauthorized users" do
    log_in_as(users(:southwest))
    get statistics_path
    assert_response :forbidden
  end

  test "index() returns HTTP 200 for authorized users" do
    log_in_as(users(:southwest_sysadmin))
    get statistics_path
    assert_response :ok
  end

  test "index() respects role limits" do
    log_in_as(users(:southwest_sysadmin))
    get statistics_path
    assert_response :ok

    get statistics_path(role: Role::LOGGED_OUT)
    assert_response :forbidden
  end

  # items()

  test "items() returns HTTP 403 for logged-out users" do
    get statistics_items_path, xhr: true
    assert_response :forbidden
  end

  test "items() returns HTTP 403 for unauthorized users" do
    log_in_as(users(:southwest))
    get statistics_items_path, xhr: true
    assert_response :forbidden
  end

  test "items() returns HTTP 200 for authorized users" do
    log_in_as(users(:southwest_sysadmin))
    get statistics_items_path, xhr: true
    assert_response :ok
  end

  test "items() returns HTTP 404 for non-XHR requests" do
    log_in_as(users(:southwest_sysadmin))
    get statistics_items_path
    assert_response :not_found
  end

  test "items() respects role limits" do
    log_in_as(users(:southwest_sysadmin))
    get statistics_items_path, xhr: true
    assert_response :ok

    get statistics_items_path(role: Role::LOGGED_OUT), xhr: true
    assert_response :forbidden
  end

end
