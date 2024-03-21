require 'test_helper'

class ApplicationControllerTest < ActionDispatch::IntegrationTest

  setup do
    host! institutions(:southwest).fqdn
    setup_opensearch
  end

  test "disabled users are logged out" do
    user = users(:southwest)
    log_in_as(user)
    get root_path
    assert_response :ok

    user.update!(enabled: false)
    get root_path
    assert_redirected_to root_path
  end

end
