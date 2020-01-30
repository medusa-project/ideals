require 'test_helper'

class SessionsControllerTest < ActionDispatch::IntegrationTest

  setup do
    # https://github.com/omniauth/omniauth/wiki/Integration-Testing
    OmniAuth.config.test_mode = true
    user = user_identity(:admin)
    OmniAuth.config.mock_auth[:identity] = OmniAuth::AuthHash.new(provider: "identity",
                                                                  uid: user.uid,
                                                                  info: {
                                                                      name: 'Admin',
                                                                      email: user.email
                                                                  })
    Rails.application.env_config["omniauth.auth"] = OmniAuth.config.mock_auth[:identity]
  end

  teardown do
    OmniAuth.config.mock_auth[:identity] = nil
  end

  # create()

  test 'create() with valid credentials' do
    post "/auth/identity/callback"
    assert_redirected_to root_url
  end

  test "create() with invalid credentials" do
    OmniAuth.config.mock_auth[:identity] = :invalid_credentials
    post "/auth/identity/callback"
    assert_redirected_to "http://www.example.com/auth/failure?message=invalid_credentials&strategy=identity"
  end

  # destroy()

  test "destroy() redirects to the root URL" do
    get logout_path
    assert_redirected_to root_url
  end

  # new()

  test "new() redirects to shibboleth login path" do
    get login_path
    assert_redirected_to "http://www.example.com/Shibboleth.sso/Login?target=https://localhost/auth/shibboleth/callback"
  end

end
