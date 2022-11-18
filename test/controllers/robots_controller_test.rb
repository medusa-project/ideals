require 'test_helper'

class RobotsControllerTest < ActionDispatch::IntegrationTest

  # show()

  test "show() returns HTTP 200" do
    get robots_path
    assert_response :ok
  end

  test "show() returns correct content" do
    get robots_path
    assert response.body.include?("Disallow")
  end

end
