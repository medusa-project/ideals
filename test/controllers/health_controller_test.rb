require "test_helper"

class HealthControllerTest < ActionDispatch::IntegrationTest

  test "index() returns HTTP 200" do
    get health_path
    assert_response :ok
  end

end
