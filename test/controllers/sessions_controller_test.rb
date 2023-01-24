require 'test_helper'

class SessionsControllerTest < ActionDispatch::IntegrationTest

  setup do
    @institution = institutions(:example)
    host! @institution.fqdn
  end

  teardown do
    log_out
  end

  # create()

  test "create() with invalid credentials redirects to failure route" do
    post "/auth/identity/callback", params: {
        auth_key: "bogus@example.edu",
        password: "WRONG"
    }
    assert_redirected_to @institution.scope_url + "/auth/failure?message=invalid_credentials&strategy=identity"
  end

  test "create() with a non-activated user redirects to the return URL" do
    user = users(:example)
    user.identity.update_attribute(:activated, false)
    post "/auth/identity/callback", params: {
        auth_key: user.email,
        password: "password"
    }
    assert_redirected_to @institution.scope_url
  end

  test "create() via XHR with a non-activated user returns HTTP 403" do
    user = users(:example)
    user.identity.update_attribute(:activated, false)
    post "/auth/identity/callback", params: {
      auth_key: user.email,
      password: "password"
    }, xhr: true
    assert_response :forbidden
  end

  test "create() with a disabled user redirects to the return URL" do
    user = users(:example)
    user.update!(enabled: false)
    post "/auth/identity/callback", params: {
      auth_key: user.email,
      password: "password"
    }
    assert_redirected_to @institution.scope_url
  end

  test "create() via XHR with a disabled user returns HTTP 403" do
    user = users(:example)
    user.update!(enabled: false)
    post "/auth/identity/callback", params: {
      auth_key: user.email,
      password: "password"
    }, xhr: true
    assert_response :forbidden
  end

  test "create() with user of different institution redirects to the return
  URL" do
    user = users(:northeast)
    post "/auth/identity/callback", params: {
      auth_key: user.email,
      password: "password"
    }
    assert_redirected_to @institution.scope_url
  end

  test "create() via XHR with user of different institution returns HTTP 403" do
    user = users(:northeast)
    post "/auth/identity/callback", params: {
      auth_key: user.email,
      password: "password"
    }, xhr: true
    assert_response :forbidden
  end

  test "create() with valid credentials redirects to root URL" do
    user = users(:example)
    user.institution.update!(default: true)
    post "/auth/identity/callback", params: {
        auth_key: user.email,
        password: "password"
    }
    assert_redirected_to @institution.scope_url
  end

  test "create() via XHR with valid credentials redirects to root URL" do
    user = users(:example)
    user.institution.update!(default: true)
    post "/auth/identity/callback", params: {
      auth_key: user.email,
      password: "password"
    }, xhr: true
    assert_redirected_to @institution.scope_url
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

  test "destroy() redirects to the root URL in a globally-scoped context" do
    host! ::Configuration.instance.main_host
    get logout_path
    assert_redirected_to root_url
  end

  test "destroy() redirects to the root URL in an institution-scoped context" do
    institution = institutions(:southwest)
    host! institution.fqdn
    get logout_path
    assert_redirected_to institution.scope_url
  end

  # new_netid()

  test "new_netid() redirects to netid login path" do
    get netid_login_path
    assert_redirected_to @institution.scope_url + "/auth/developer"
  end

end
