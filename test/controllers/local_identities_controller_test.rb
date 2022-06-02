require 'test_helper'

class LocalIdentitiesControllerTest < ActionDispatch::IntegrationTest

  # activate()

  test "activate() redirects to root path for logged-in users" do
    identity = local_identities(:approved)
    get local_identity_activate_path(identity)
    assert_redirected_to root_path
  end

  test "activate() redirects and sets the flash if a token is not provided" do
    identity = local_identities(:approved)
    get local_identity_activate_path(identity)
    assert_equal "Invalid activation link.", flash['error']
    assert_redirected_to root_url
  end

  test "activate() redirects and sets the flash if an invalid token is provided" do
    identity = local_identities(:approved)
    get local_identity_activate_path(identity, token: "bogus")
    assert_equal "Invalid activation link.", flash['error']
    assert_redirected_to root_url
  end

  test "activate() activates the instance and redirects if all arguments are valid" do
    identity = local_identities(:approved)
    assert !identity.activated
    identity.create_activation_digest
    token    = identity.activation_token

    get local_identity_activate_path(identity, token: token)
    identity.reload
    assert identity.activated
    assert_redirected_to login_url
  end

  # edit_password()

  test "edit_password() returns HTTP 403 for logged-out users" do
    identity = local_identities(:local_sysadmin)
    get local_identity_edit_password_path(identity), xhr: true
    assert_response :forbidden
  end

  test "edit_password() returns HTTP 403 for unauthorized users" do
    log_in_as(users(:norights))
    identity = local_identities(:local_sysadmin)
    get local_identity_edit_password_path(identity), xhr: true
    assert_response :forbidden
  end

  test "edit_password() returns HTTP 403 for users other than the user whose
  password is being changed" do
    log_in_as(users(:local_sysadmin))
    identity = local_identities(:norights)
    get local_identity_edit_password_path(identity), xhr: true
    assert_response :forbidden
  end

  test "edit_password() returns HTTP 200 for authorized users" do
    log_in_as(users(:local_sysadmin))
    identity = local_identities(:local_sysadmin)
    get local_identity_edit_password_path(identity), xhr: true
    assert_response :ok
  end

  test "edit_password() respects role limits" do
    log_in_as(users(:local_sysadmin))
    identity = local_identities(:local_sysadmin)
    get local_identity_edit_password_path(identity), xhr: true
    assert_response :ok

    get local_identity_edit_password_path(identity,
                                          role: Role::LOGGED_OUT), xhr: true
    assert_response :forbidden
  end

  # new_password()

  test "new_password() redirects to root path for logged-in users" do
    identity = local_identities(:approved)
    get local_identity_reset_password_path(identity)
    assert_redirected_to root_path
  end

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

  # register()

  test "register() redirects to root path for logged-in users" do
    identity = local_identities(:approved)
    get local_identity_register_path(identity)
    assert_redirected_to root_path
  end

  test "register() redirects and sets the flash if a token is not provided" do
    identity = local_identities(:norights)
    get local_identity_register_path(identity)
    assert_equal "Invalid registration link.", flash['error']
    assert_redirected_to root_url
  end

  test "register() redirects and sets the flash if an invalid token is provided" do
    identity = local_identities(:norights)
    get local_identity_register_path(identity, token: "bogus")
    assert_equal "Invalid registration link.", flash['error']
    assert_redirected_to root_url
  end

  test "register() returns HTTP 200 if a valid token is provided" do
    identity = local_identities(:norights)
    identity.update_attribute(:activated, false)
    identity.create_registration_digest
    token = identity.registration_token

    get local_identity_register_path(identity, token: token)
    assert_response :ok
  end

  # reset_password()

  test "reset_password() redirects to root path for logged-in users" do
    identity = local_identities(:approved)
    post local_identity_reset_password_path(identity)
    assert_redirected_to root_path
  end

  test "reset_password() redirects and sets the flash if a token is not provided" do
    identity = local_identities(:norights)
    post local_identity_reset_password_path(identity),
         params: {
             local_identity: {
                 password: "MyNewPassword123",
                 password_confirmation: "MyNewPassword123"
             }
         }
    assert_equal "Invalid password reset link.", flash['error']
    assert_redirected_to root_url
  end

  test "reset_password() redirects and sets the flash if an invalid token is provided" do
    identity = local_identities(:norights)
    post local_identity_reset_password_path(identity),
         params: {
             token: "bogus",
             local_identity: {
                 password: "MyNewPassword123",
                 password_confirmation: "MyNewPassword123"
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

    post local_identity_reset_password_path(identity),
         params: {
             token: token,
             local_identity: {
                 password: "MyNewPassword123",
                 password_confirmation: "MyNewPassword123"
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

    post local_identity_reset_password_path(identity),
         params: {
             token: token,
             local_identity: {
                 password: "MyNewPassword123",
                 password_confirmation: "ThisDoesNotMatch123"
             }
         }
    assert flash['error'].include?("Password confirmation doesn't match")
  end

  test "reset_password() sets the flash and redirects if all arguments are valid" do
    identity = local_identities(:norights)
    identity.create_reset_digest
    token    = identity.reset_token
    password = "MyNewPassword123"

    post local_identity_reset_password_path(identity),
         params: {
             token: token,
             local_identity: {
                 password: password,
                 password_confirmation: password
             }
         }
    assert flash['success'].start_with?("Your password has been changed")
    assert_redirected_to root_url
  end

  # update()

  test "update() redirects to root path for logged-in users" do
    identity = local_identities(:approved)
    patch local_identity_path(identity)
    assert_redirected_to root_path
  end

  test "update() redirects and sets the flash if a token is not provided" do
    identity = local_identities(:approved)
    patch local_identity_path(identity),
          params: {
              local_identity: {
                  password: "MyNewPassword123",
                  password_confirmation: "MyNewPassword123",
                  user_attributes: {
                      name: "New Name",
                      phone: "555-555-5555"
                  }
              }
          }
    assert_equal "Invalid registration link.", flash['error']
    assert_redirected_to root_url
  end

  test "update() redirects and sets the flash if an invalid token is provided" do
    identity = local_identities(:approved)
    patch local_identity_path(identity),
          params: {
              token: "bogus",
              local_identity: {
                  password: "MyNewPassword123",
                  password_confirmation: "MyNewPassword123",
                  user_attributes: {
                      name: "New Name",
                      phone: "555-555-5555"
                  }
              }
          }
    assert_equal "Invalid registration link.", flash['error']
    assert_redirected_to root_url
  end

  test "update() sets the flash if the password does not match the confirmation" do
    identity = local_identities(:approved)
    identity.create_registration_digest
    token = identity.registration_token

    patch local_identity_path(identity),
          params: {
              token: token,
              local_identity: {
                  password: "MyNewPassword123",
                  password_confirmation: "ThisDoesNotMatch123",
                  user_attributes: {
                      name: "New Name",
                      phone: "555-555-5555"
                  }
              }
          }
    assert flash['error'].include?("Password confirmation doesn't match")
  end

  test "update() updates the instance and sends an email if all arguments
  are valid" do
    identity = local_identities(:approved)
    identity.create_registration_digest
    token    = identity.registration_token
    name     = "New Name"
    phone    = "555-555-5555"
    password = "MyNewPassword123"

    assert_emails 1 do
      patch local_identity_path(identity),
            params: {
                token: token,
                local_identity: {
                    password: password,
                    password_confirmation: password,
                    user_attributes: {
                        name:     name,
                        phone:    phone
                    }
                }
            }
      identity.reload
      user = identity.user
      assert_equal name, user.name
      assert_equal phone, user.phone
    end
  end

  test "update() sets the flash and redirects if all arguments are valid" do
    identity = local_identities(:approved)
    identity.create_registration_digest
    token    = identity.registration_token
    password = "MyNewPassword123"

    patch local_identity_path(identity),
          params: {
              token: token,
              local_identity: {
                  password: password,
                  password_confirmation: password,
                  user_attributes: {
                      name: "New Name",
                      phone: "555-555-5555"
                  }
              }
          }
    assert flash['success'].start_with?("Thanks for registering!")
    assert_redirected_to root_url
  end

  # update_password()

  test "update_password() returns HTTP 403 for logged-out users" do
    identity = local_identities(:local_sysadmin)
    patch local_identity_update_password_path(identity), xhr: true
    assert_response :forbidden
  end

  test "update_password() returns HTTP 403 for unauthorized users" do
    log_in_as(users(:norights))
    identity = local_identities(:local_sysadmin)
    patch local_identity_update_password_path(identity), xhr: true
    assert_response :forbidden
  end

  test "update_password() returns HTTP 400 if the current password is not supplied" do
    log_in_as(users(:local_sysadmin))
    identity = local_identities(:local_sysadmin)
    password = "MyNewPassword123"
    patch local_identity_update_password_path(identity),
          xhr: true,
          params: {
              local_identity: {
                  password: password,
                  password_confirmation: password
              }
          }
    assert_response :bad_request
  end

  test "update_password() returns HTTP 400 if the current password is incorrect" do
    log_in_as(users(:local_sysadmin))
    identity = local_identities(:local_sysadmin) # password is `password`
    password = "MyNewPassword123"
    patch local_identity_update_password_path(identity),
          xhr: true,
          params: {
              current_password: "bogus",
              local_identity: {
                  password: password,
                  password_confirmation: password
              }
          }
    assert_response :bad_request
  end

  test "update_password() returns HTTP 400 if the new password does not match
  the confirmation" do
    log_in_as(users(:local_sysadmin))
    identity = local_identities(:local_sysadmin) # password is `password`

    patch local_identity_update_password_path(identity),
          xhr: true,
          params: {
              current_password: "password",
              local_identity: {
                  password: "MyNewPassword123",
                  password_confirmation: "wrong"
              }
          }
    assert_response :bad_request
  end

  test "update_password() updates the password and returns HTTP 200" do
    log_in_as(users(:norights))
    identity = local_identities(:norights)
    password = "MyNewPassword123"
    patch local_identity_update_password_path(identity),
          xhr: true,
          params: {
              current_password: "password",
              local_identity: {
                  password: password,
                  password_confirmation: password
              }
          }
    assert_response :ok
    identity.reload
    assert identity.authenticated?(:password, password)
  end

  test "update_password() returns HTTP 404 for nonexistent identities" do
    log_in_as(users(:local_sysadmin))
    patch "/identities/99999999/update-password", xhr: true
    assert_response :not_found
  end

end
