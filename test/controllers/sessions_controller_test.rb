require 'test_helper'

class SessionsControllerTest < ActionDispatch::IntegrationTest

  teardown do
    log_out
  end

  # create()

  test 'create() with valid credentials' do
    user = users(:admin)
    post '/auth/identity/callback', params: {
        auth_key: "#{user.username}@illinois.edu",
        password: "password"
    }
    assert_redirected_to root_url
  end

  test "create() with invalid credentials" do
    post '/auth/identity/callback', params: {
        auth_key: "bogus@illinois.edu",
        password: "WRONG"
    }
    assert_redirected_to "http://www.example.com/auth/failure?message=invalid_credentials&strategy=identity"
  end

  # destroy()

  test "destroy() redirects to the root URL" do
    get logout_path
    assert_redirected_to root_url
  end

  # new()

  test "new() displays the login page" do
    get login_path
    assert_response :ok
  end

  # new_netid()

  test "new_netid() redirects to netid login path" do
    get netid_login_path
    assert_redirected_to "http://www.example.com/Shibboleth.sso/Login?target=https://localhost/auth/shibboleth/callback"
  end

end
