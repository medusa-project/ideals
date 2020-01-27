require 'test_helper'

class RegisteredElementsControllerTest < ActionDispatch::IntegrationTest

  setup do
    log_in_as(user_identity(:admin))
  end

  # index()

  test "index() returns HTTP 200" do
    get registered_elements_path
    assert_response :ok
  end

end
