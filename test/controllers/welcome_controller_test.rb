require 'test_helper'

class WelcomeControllerTest < ActionDispatch::IntegrationTest

  setup do
    host! institutions(:southwest).fqdn
    setup_opensearch
  end

  teardown do
    log_out
  end

  # about()

  test "about() returns HTTP 404 for unscoped requests" do
    host! ::Configuration.instance.main_host
    get about_path
    assert_response :not_found
  end

  test "about() returns HTTP 200" do
    get about_path
    assert_response :ok
  end

  # index()

  test "index() returns HTTP 200" do
    get root_path
    assert_response :ok
  end

end
