require 'test_helper'

class SessionsControllerTest < ActionDispatch::IntegrationTest

  teardown do
    log_out
  end

  # create()

  test "create() with invalid credentials redirects to failure route" do
    post "/auth/identity/callback", params: {
        auth_key: "bogus@example.edu",
        password: "WRONG"
    }
    assert_redirected_to "http://www.example.com/auth/failure?message=invalid_credentials&strategy=identity"
  end

  test "create() with a non-activated user responds with HTTP 401" do
    user = users(:example)
    user.identity.update_attribute(:activated, false)
    post "/auth/identity/callback", params: {
        auth_key: user.email,
        password: "password"
    }
    assert_response :unauthorized
  end

  test "create() with a disabled user responds with HTTP 401" do
    user = users(:example)
    user.update!(enabled: false)
    post "/auth/identity/callback", params: {
      auth_key: user.email,
      password: "password"
    }
    assert_response :unauthorized
  end

  test "create() with user of different institution responds with HTTP 401" do
    host! institutions(:southwest).fqdn
    user = users(:northeast)
    post "/auth/identity/callback", params: {
      auth_key: user.email,
      password: "password"
    }
    assert_response :unauthorized
  end

  test "create() with valid credentials redirects to root URL" do
    user = users(:example)
    user.institution.update!(default: true)
    post "/auth/identity/callback", params: {
        auth_key: user.email,
        password: "password"
    }
    assert_redirected_to root_url
  end

  test "create() with valid credentials sets the user's auth hash" do
    user = users(:example)
    user.institution.update!(default: true)
    user.update!(auth_hash: nil)
    post "/auth/identity/callback", params: {
      auth_key: user.email,
      password: "password"
    }
    user.reload
    assert_not_nil user.auth_hash
  end

  test "create() with valid credentials sets the user's last-logged-in time" do
    user = users(:example)
    user.institution.update!(default: true)
    post "/auth/identity/callback", params: {
      auth_key: user.email,
      password: "password"
    }
    user.reload
    assert user.last_logged_in_at > 5.seconds.ago
  end

  # destroy()

  test "destroy() redirects to the root URL" do
    get logout_path
    assert_redirected_to root_url
  end

  # new_netid()

  test "new_netid() redirects to netid login path" do
    get netid_login_path
    assert_redirected_to "http://www.example.com/auth/developer"
  end

end
