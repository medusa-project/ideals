require 'test_helper'

class FileFormatsControllerTest < ActionDispatch::IntegrationTest

  setup do
    host! institutions(:southwest).fqdn
  end

  teardown do
    log_out
  end

  # index()

  test "index() returns HTTP 404 for unscoped requests" do
    host! ::Configuration.instance.main_host
    get file_formats_path
    assert_response :not_found
  end

  test "index() redirects to root page for logged-out users" do
    get file_formats_path
    assert_redirected_to institutions(:southwest).scope_url
  end

  test "index() returns HTTP 403 for unauthorized users" do
    log_in_as(users(:southwest))
    get file_formats_path
    assert_response :forbidden
  end

  test "index() returns HTTP 200 for authorized users" do
    log_in_as(users(:southwest_sysadmin))
    get file_formats_path
    assert_response :ok
  end

  test "index() respects role limits" do
    log_in_as(users(:southwest_sysadmin))
    get file_formats_path
    assert_response :ok

    get file_formats_path(role: Role::LOGGED_OUT)
    assert_response :forbidden
  end

end
