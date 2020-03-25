require 'test_helper'

class DashboardControllerTest < ActionDispatch::IntegrationTest

  teardown do
    log_out
  end

  # index()

  test "index() redirects to the login path for logged-out users" do
    get dashboard_path
    assert_redirected_to login_path
  end

  test "index() returns HTTP 200 for logged-in users" do
    log_in_as(users(:sally))
    get dashboard_path
    assert_response :ok
    assert_select "h1", "Dashboard"
  end

end
