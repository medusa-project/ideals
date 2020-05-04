require 'test_helper'

class LocalIdentitiesControllerTest < ActionDispatch::IntegrationTest

  # new_password()

  test "new_password() redirects and sets the flash if a token is not provided" do
    identity = local_identities(:norights)
    get local_identity_reset_password_path(identity)
    assert_equal "Invalid password reset link.", flash['error']
    assert_redirected_to root_url
  end

  test "new_password() redirects and sets the flash if an invalid token is provided" do
    identity = local_identities(:norights)
    get local_identity_reset_password_path(identity, token: "bogus")
    assert_equal "Invalid password reset link.", flash['error']
    assert_redirected_to root_url
  end

  test "new_password() redirects and sets the flash if an expired token is provided" do
    identity = local_identities(:norights)
    identity.create_reset_digest
    token = identity.reset_token
    identity.update_attribute(:reset_sent_at, Time.now - 1.month)

    get local_identity_reset_password_path(identity, token: token)
    assert_equal "This password reset link has expired. Please try again.",
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
    assert_equal "Invalid password reset link.", flash['error']
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
    assert_equal "Invalid password reset link.", flash['error']
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
    assert_equal "This password reset link has expired. Please try again.",
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

  # register()

  # TODO: write tests for this

end
