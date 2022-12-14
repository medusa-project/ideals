require 'test_helper'

class FileFormatsControllerTest < ActionDispatch::IntegrationTest

  teardown do
    log_out
  end

  # index()

  test "index() redirects to root page for logged-out users" do
    get file_formats_path
    assert_redirected_to root_path
  end

  test "index() returns HTTP 403 for unauthorized users" do
    log_in_as(users(:norights))
    get file_formats_path
    assert_response :forbidden
  end

  test "index() returns HTTP 200 for authorized users" do
    log_in_as(users(:local_sysadmin))
    get file_formats_path
    assert_response :ok
  end

  test "index() respects role limits" do
    log_in_as(users(:local_sysadmin))
    get file_formats_path
    assert_response :ok

    get file_formats_path(role: Role::LOGGED_OUT)
    assert_response :forbidden
  end

end
