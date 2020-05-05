require 'test_helper'

class SessionsControllerTest < ActionDispatch::IntegrationTest

  teardown do
    log_out
  end

  # create()

  test "create() with invalid credentials redirects to failure route" do
    post '/auth/identity/callback', params: {
        auth_key: "bogus@illinois.edu",
        password: "WRONG"
    }
    assert_redirected_to "http://www.example.com/auth/failure?message=invalid_credentials&strategy=identity"
  end

  test "create() with non-activated user responds with HTTP 401" do
    user = users(:norights)
    user.identity.update_attribute(:activated, false)
    post '/auth/identity/callback', params: {
        auth_key: "#{user.username}@illinois.edu",
        password: "password"
    }
    assert_response :unauthorized
  end

  test "create() with valid credentials redirects to root URL" do
    user = users(:norights)
    post '/auth/identity/callback', params: {
        auth_key: "#{user.username}@illinois.edu",
        password: "password"
    }
    assert_redirected_to root_url
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
