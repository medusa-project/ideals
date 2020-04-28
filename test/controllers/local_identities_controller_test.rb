require 'test_helper'

class LocalIdentitiesControllerTest < ActionDispatch::IntegrationTest

  # activate()

  test "activate() sets the flash and redirects if a token is not provided" do
    identity = local_identities(:norights)
    post local_identity_activate_path(identity), {
        params: {}
    }
    assert_equal "Invalid activation link.", flash['error']
    assert_redirected_to root_url
  end

  test "activate() sets the flash and redirects if an invalid token is provided" do
    identity = local_identities(:norights)
    post local_identity_activate_path(identity), {
        params: {
            token: "bogus"
        }
    }
    assert_equal "Invalid activation link.", flash['error']
    assert_redirected_to root_url
  end

  test "activate() sets the flash and redirects if the identity has already been activated" do
    identity = local_identities(:norights)
    identity.send(:create_activation_digest)
    identity.activate

    post local_identity_activate_path(identity), {
        params: {
            token: identity.activation_token
        }
    }
    assert_equal "This account has already been activated.", flash['error']
    assert_redirected_to root_url
  end

  test "activate() activates the identity, sets the flash, and redirects" do
    identity = local_identities(:norights)
    identity.send(:create_activation_digest)
    identity.update_attribute(:activated, false)
    identity.update_attribute(:activated_at, nil)

    post local_identity_activate_path(identity), {
        params: {
            token: identity.activation_token
        }
    }
    identity.reload
    assert identity.activated
    assert_not_nil identity.activated_at
    assert_equal "Account activated.", flash['success']
    assert_redirected_to root_url
  end

  test "activate() responds to HTTP GET" do
    identity = local_identities(:norights)
    identity.send(:create_activation_digest)
    identity.update_attribute(:activated, false)
    identity.update_attribute(:activated_at, nil)

    get local_identity_activate_path(identity), {
        params: {
            token: identity.activation_token
        }
    }
    identity.reload
    assert identity.activated
    assert_not_nil identity.activated_at
    assert_equal "Account activated.", flash['success']
    assert_redirected_to root_url
  end

  test "activate() responds to HTTP PATCH" do
    identity = local_identities(:norights)
    identity.send(:create_activation_digest)
    identity.update_attribute(:activated, false)
    identity.update_attribute(:activated_at, nil)

    patch local_identity_activate_path(identity), {
        params: {
            token: identity.activation_token
        }
    }
    identity.reload
    assert identity.activated
    assert_not_nil identity.activated_at
    assert_equal "Account activated.", flash['success']
    assert_redirected_to root_url
  end

  test "activate() responds to HTTP POST" do
    identity = local_identities(:norights)
    identity.send(:create_activation_digest)
    identity.update_attribute(:activated, false)
    identity.update_attribute(:activated_at, nil)

    post local_identity_activate_path(identity), {
        params: {
            token: identity.activation_token
        }
    }
    identity.reload
    assert identity.activated
    assert_not_nil identity.activated_at
    assert_equal "Account activated.", flash['success']
    assert_redirected_to root_url
  end

  # new_password()

  test "new_password() redirects and sets the flash if a token is not provided" do
    identity = local_identities(:norights)
    get local_identity_reset_password_path(identity)
    assert_equal "Invalid token.", flash['error']
    assert_redirected_to root_url
  end

  test "new_password() redirects and sets the flash if an invalid token is provided" do
    identity = local_identities(:norights)
    get local_identity_reset_password_path(identity, token: "bogus")
    assert_equal "Invalid token.", flash['error']
    assert_redirected_to root_url
  end

  test "new_password() redirects and sets the flash if an expired token is provided" do
    identity = local_identities(:norights)
    identity.create_reset_digest
    token = identity.reset_token
    identity.update_attribute(:reset_sent_at, Time.now - 1.month)

    get local_identity_reset_password_path(identity, token: token)
    assert_equal "This password reset request has expired. Please try again.",
                 flash['error']
    assert_redirected_to reset_password_url
  end

  test "new_password() returns HTTP 200 if a valid token is provided" do
    identity = local_identities(:norights)
    identity.create_reset_digest
    token = identity.reset_token

    get local_identity_reset_password_path(identity, token: token)
    assert_response :ok
  end

  # reset_password()

  test "reset_password() redirects and sets the flash if a token is not provided" do
    identity = local_identities(:norights)
    post local_identity_reset_password_path(identity), {
        params: {
            local_identity: {
                password: "MyNewPassword123",
                password_confirmation: "MyNewPassword123"
            }
        }
    }
    assert_equal "Invalid token.", flash['error']
    assert_redirected_to root_url
  end

  test "reset_password() redirects and sets the flash if an invalid token is provided" do
    identity = local_identities(:norights)
    post local_identity_reset_password_path(identity), {
        params: {
            token: "bogus",
            local_identity: {
                password: "MyNewPassword123",
                password_confirmation: "MyNewPassword123"
            }
        }
    }
    assert_equal "Invalid token.", flash['error']
    assert_redirected_to root_url
  end

  test "reset_password() redirects and sets the flash if an expired token is provided" do
    identity = local_identities(:norights)
    identity.create_reset_digest
    token = identity.reset_token
    identity.update_attribute(:reset_sent_at, Time.now - 1.month)

    post local_identity_reset_password_path(identity), {
        params: {
            token: token,
            local_identity: {
                password: "MyNewPassword123",
                password_confirmation: "MyNewPassword123"
            }
        }
    }
    assert_equal "This password reset request has expired. Please try again.",
                 flash['error']
    assert_redirected_to reset_password_url
  end

  test "reset_password() sets the flash if the password does not match the confirmation" do
    identity = local_identities(:norights)
    identity.create_reset_digest
    token = identity.reset_token

    post local_identity_reset_password_path(identity), {
        params: {
            token: token,
            local_identity: {
                password: "MyNewPassword123",
                password_confirmation: "ThisDoesNotMatch123"
            }
        }
    }
    assert flash['error'].include?("Password confirmation doesn't match")
  end

  test "reset_password() sets the flash and redirects if all arguments are valid" do
    identity = local_identities(:norights)
    identity.create_reset_digest
    token    = identity.reset_token
    password = "MyNewPassword123"

    post local_identity_reset_password_path(identity), {
        params: {
            token: token,
            local_identity: {
                password: password,
                password_confirmation: password
            }
        }
    }
    assert flash['success'].start_with?("Your password has been changed")
    assert_redirected_to root_url
  end

end
