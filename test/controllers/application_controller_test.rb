require 'test_helper'

class ApplicationControllerTest < ActionDispatch::IntegrationTest

  test "disabled users are logged out" do
    user = users(:norights)
    log_in_as(user)
    get items_path
    assert_response :ok

    user.update!(enabled: false)
    get items_path
    assert_redirected_to root_path
  end

end
