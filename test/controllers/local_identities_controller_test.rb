require 'test_helper'

class LocalIdentitiesControllerTest < ActionDispatch::IntegrationTest

  setup do
    @institution = institutions(:southwest)
    host! @institution.fqdn
    @identity = local_identities(:southwest)
  end

  # create()

  test "create() returns HTTP 404 for unscoped requests" do
    host! ::Configuration.instance.main_host
    user = users(:southwest_sysadmin)
    user.identity.destroy!
    post user_local_identities_path(user)
    assert_response :not_found
  end

  test "create() redirects to root page for logged-out users" do
    user = users(:southwest_sysadmin)
    user.identity.destroy!
    post user_local_identities_path(user)
    assert_redirected_to @identity.user.institution.scope_url
  end

  test "create() returns HTTP 403 for unauthorized users" do
    user = users(:southwest_sysadmin)
    user.identity.destroy!
    log_in_as(user)
    post user_local_identities_path(user),
         xhr: true,
         params: {
           local_identity: {
             password:              "MyNewPassword123!",
             password_confirmation: "MyNewPassword123!"
           }
         }
    assert_response :forbidden
  end

  test "create() returns HTTP 200" do
    user = users(:southwest_sysadmin)
    log_in_as(user)
    user.identity.destroy! # do this after logging in, otherwise we wouldn't be able to
    post user_local_identities_path(user),
         xhr: true,
         params: {
           local_identity: {
             password:              "MyNewPassword123!",
             password_confirmation: "MyNewPassword123!"
           }
         }
    assert_response :ok
  end

  test "create() creates a LocalIdentity" do
    user = users(:southwest_sysadmin)
    log_in_as(user)
    user.identity.destroy! # do this after logging in, otherwise we wouldn't be able to
    assert_difference "LocalIdentity.count" do
      post user_local_identities_path(user),
           xhr: true,
           params: {
             local_identity: {
               password:              "MyNewPassword123!",
               password_confirmation: "MyNewPassword123!"
             }
           }
    end
  end

  test "create() returns HTTP 400 for illegal arguments" do
    user = users(:southwest_sysadmin)
    log_in_as(user)
    post user_local_identities_path(user),
         xhr: true,
         params: {
           local_identity: {
             password:              "MyNewPassword123!",
             password_confirmation: "DoesNotMatch123!"
           }
         }
    assert_response :bad_request
  end

  # edit_password()

  test "edit_password() returns HTTP 404 for unscoped requests" do
    host! ::Configuration.instance.main_host
    @identity = local_identities(:southwest_sysadmin)
    get local_identity_edit_password_path(@identity), xhr: true
    assert_response :not_found
  end

  test "edit_password() returns HTTP 403 for logged-out users" do
    @identity = local_identities(:southwest_sysadmin)
    get local_identity_edit_password_path(@identity), xhr: true
    assert_response :forbidden
  end

  test "edit_password() returns HTTP 403 for unauthorized users" do
    log_in_as(users(:southwest))
    @identity = local_identities(:southwest_admin)
    get local_identity_edit_password_path(@identity), xhr: true
    assert_response :forbidden
  end

  test "edit_password() returns HTTP 403 for users other than the user whose
  password is being changed" do
    log_in_as(users(:southwest_sysadmin))
    get local_identity_edit_password_path(@identity), xhr: true
    assert_response :forbidden
  end

  test "edit_password() returns HTTP 200 for authorized users" do
    log_in_as(users(:southwest))
    get local_identity_edit_password_path(@identity), xhr: true
    assert_response :ok
  end

  test "edit_password() respects role limits" do
    log_in_as(users(:southwest_sysadmin))
    @identity = local_identities(:southwest_sysadmin)
    get local_identity_edit_password_path(@identity), xhr: true
    assert_response :ok

    get local_identity_edit_password_path(@identity,
                                          role: Role::LOGGED_OUT), xhr: true
    assert_response :forbidden
  end

  # new()

  test "new() returns HTTP 404 for unscoped requests" do
    host! ::Configuration.instance.main_host
    get new_user_local_identity_path(@identity.user)
    assert_response :not_found
  end

  test "new() redirects to root page for logged-out users" do
    get new_user_local_identity_path(@identity.user)
    assert_redirected_to @identity.user.institution.scope_url
  end

  test "new() returns HTTP 403 for unauthorized users" do
    log_in_as(users(:southwest))
    get new_user_local_identity_path(@identity.user)
    assert_response :forbidden
  end

  test "new() returns HTTP 200 for authorized users" do
    log_in_as(users(:southwest_sysadmin))
    get new_user_local_identity_path(@identity.user)
    assert_response :ok
  end

  # new_password()

  test "new_password() returns HTTP 404 for unscoped requests" do
    host! ::Configuration.instance.main_host
    get local_identity_reset_password_path(@identity)
    assert_response :not_found
  end

  test "new_password() redirects to root path for logged-in users" do
    get local_identity_reset_password_path(@identity)
    assert_redirected_to root_path
  end

  test "new_password() redirects and sets the flash if a token is not provided" do
    get local_identity_reset_password_path(@identity)
    assert_equal "Invalid password reset link.", flash['error']
    assert_redirected_to root_url
  end

  test "new_password() redirects and sets the flash if an invalid token is
  provided" do
    get local_identity_reset_password_path(@identity, token: "bogus")
    assert_equal "Invalid password reset link.", flash['error']
    assert_redirected_to root_url
  end

  test "new_password() redirects and sets the flash if an expired token is
  provided" do
    @identity.create_reset_digest
    token = @identity.reset_token
    @identity.update_attribute(:reset_sent_at, Time.now - 1.month)

    get local_identity_reset_password_path(@identity, token: token)
    assert_equal "This password reset link has expired. Please try again.",
                 flash['error']
    assert_redirected_to reset_password_url
  end

  test "new_password() returns HTTP 200 if a valid token is provided" do
    @identity.create_reset_digest
    token = @identity.reset_token

    get local_identity_reset_password_path(@identity, token: token)
    assert_response :ok
  end

  # register()

  test "register() returns HTTP 404 for unscoped requests" do
    host! ::Configuration.instance.main_host
    get local_identity_register_path(@identity)
    assert_response :not_found
  end

  test "register() redirects to root path for logged-in users" do
    get local_identity_register_path(@identity)
    assert_redirected_to root_path
  end

  test "register() redirects and sets the flash if a token is not provided" do
    @identity.create_registration_digest
    get local_identity_register_path(@identity)
    assert_equal "Invalid registration link.", flash['error']
    assert_redirected_to root_url
  end

  test "register() redirects and sets the flash if an invalid token is
  provided" do
    @identity.create_registration_digest
    get local_identity_register_path(@identity, token: "bogus")
    assert_equal "Invalid registration link.", flash['error']
    assert_redirected_to root_url
  end

  test "register() returns HTTP 200 if a valid token is provided" do
    @identity.create_registration_digest
    token = @identity.registration_token

    get local_identity_register_path(@identity, token: token)
    assert_response :ok
  end

  # reset_password()

  test "reset_password() returns HTTP 404 for unscoped requests" do
    host! ::Configuration.instance.main_host
    post local_identity_reset_password_path(@identity)
    assert_response :not_found
  end

  test "reset_password() redirects to root path for logged-in users" do
    post local_identity_reset_password_path(@identity)
    assert_redirected_to root_path
  end

  test "reset_password() redirects and sets the flash if a token is not
  provided" do
    post local_identity_reset_password_path(@identity),
         params: {
             local_identity: {
                 password: "MyNewPassword123!",
                 password_confirmation: "MyNewPassword123!"
             }
         }
    assert_equal "Invalid password reset link.", flash['error']
    assert_redirected_to root_url
  end

  test "reset_password() redirects and sets the flash if an invalid token is
  provided" do
    post local_identity_reset_password_path(@identity),
         params: {
           token: "bogus",
           local_identity: {
             password: "MyNewPassword123!",
             password_confirmation: "MyNewPassword123!"
           }
         }
    assert_equal "Invalid password reset link.", flash['error']
    assert_redirected_to root_url
  end

  test "reset_password() redirects and sets the flash if an expired token is
  provided" do
    @identity.create_reset_digest
    token = @identity.reset_token
    @identity.update_attribute(:reset_sent_at, Time.now - 1.month)

    post local_identity_reset_password_path(@identity),
         params: {
           token: token,
           local_identity: {
             password: "MyNewPassword123!",
             password_confirmation: "MyNewPassword123!"
           }
         }
    assert_equal "This password reset link has expired. Please try again.",
                 flash['error']
    assert_redirected_to reset_password_url
  end

  test "reset_password() sets the flash if the password does not match the
  confirmation" do
    @identity.create_reset_digest
    token = @identity.reset_token

    post local_identity_reset_password_path(@identity),
         params: {
           token: token,
           local_identity: {
             password:              LocalIdentity.random_password,
             password_confirmation: LocalIdentity.random_password
           }
         }
    assert flash['error'].include?("Password confirmation doesn't match")
  end

  test "reset_password() sets the flash and redirects if all arguments are
  valid" do
    @identity.create_reset_digest
    token    = @identity.reset_token
    password = LocalIdentity.random_password

    post local_identity_reset_password_path(@identity),
         params: {
           token: token,
           local_identity: {
             password:              password,
             password_confirmation: password
           }
         }
    assert flash['success'].start_with?("Your password has been changed")
    assert_redirected_to root_url
  end

  # update()

  test "update() returns HTTP 404 for unscoped requests" do
    host! ::Configuration.instance.main_host
    patch local_identity_path(@identity)
    assert_response :not_found
  end

  test "update() redirects to root path for logged-in users" do
    patch local_identity_path(@identity)
    assert_redirected_to root_path
  end

  test "update() sets the flash and redirects if no token is provided" do
    @identity.create_registration_digest
    patch local_identity_path(@identity),
          params: {
            honey_email: "",
            correct_answer_hash: Digest::MD5.hexdigest("5" + ApplicationHelper::CAPTCHA_SALT),
            answer: "5",
            local_identity: {
              password: "MyNewPassword123!",
              password_confirmation: "MyNewPassword123!",
              user_attributes: {
                name: "New Name"
              }
            }
          }
    assert_equal "Invalid registration link.", flash['error']
    assert_redirected_to root_url
  end

  test "update() redirects if the instance has no registration digest" do
    @identity.update!(registration_digest: nil)
    token    = @identity.registration_token
    password = LocalIdentity.random_password

    patch local_identity_path(@identity),
          params: {
            token: token,
            honey_email: "",
            correct_answer_hash: Digest::MD5.hexdigest("5" + ApplicationHelper::CAPTCHA_SALT),
            answer: "5",
            local_identity: {
              password:              password,
              password_confirmation: password,
              user_attributes: {
                name:  "New Name"
              }
            }
          }
    assert_redirected_to root_url
  end

  test "update() sets the flash and redirects if an invalid token is
  provided" do
    @identity.create_registration_digest
    patch local_identity_path(@identity),
          params: {
            token: "bogus",
            honey_email: "",
            correct_answer_hash: Digest::MD5.hexdigest("5" + ApplicationHelper::CAPTCHA_SALT),
            answer: "5",
            local_identity: {
              password: "MyNewPassword123!",
              password_confirmation: "MyNewPassword123!",
              user_attributes: {
                name: "New Name"
              }
            }
          }
    assert_equal "Invalid registration link.", flash['error']
    assert_redirected_to root_url
  end

  test "update() sets the flash and redirects back if the password does not
  match the confirmation" do
    @identity.create_registration_digest
    token = @identity.registration_token

    patch local_identity_path(@identity),
          params: {
            token: token,
            honey_email: "",
            correct_answer_hash: Digest::MD5.hexdigest("5" + ApplicationHelper::CAPTCHA_SALT),
            answer: "5",
            local_identity: {
              password: "MyNewPassword123!",
              password_confirmation: "ThisDoesNotMatch123!",
              user_attributes: {
                name: "New Name"
              }
            }
          }
    assert flash['error'].include?("Password confirmation doesn't match")
    assert_redirected_to local_identity_register_path(@identity, token: token)
  end

  test "update() sets the flash and redirects back upon an incorrect CAPTCHA
  response" do
    @identity.create_registration_digest
    token    = @identity.registration_token
    name     = "New Name"
    password = LocalIdentity.random_password

    patch local_identity_path(@identity),
          params: {
            token: token,
            honey_email: "",
            correct_answer_hash: Digest::MD5.hexdigest("5" + ApplicationHelper::CAPTCHA_SALT),
            answer: "7", # WRONG!
            local_identity: {
              password: password,
              password_confirmation: password,
              user_attributes: {
                name: name
              }
            }
          }
    assert flash['error'].start_with?("Incorrect math question response")
    assert_redirected_to local_identity_register_path(@identity, token: token)
  end

  test "update() sets the flash and redirects if all arguments are valid" do
    @identity.create_registration_digest
    token    = @identity.registration_token
    password = LocalIdentity.random_password

    patch local_identity_path(@identity),
          params: {
            token: token,
            honey_email: "",
            correct_answer_hash: Digest::MD5.hexdigest("5" + ApplicationHelper::CAPTCHA_SALT),
            answer: "5",
            local_identity: {
              password:              password,
              password_confirmation: password,
              user_attributes: {
                name: "New Name"
              }
            }
          }
    assert flash['success'].start_with?("Thanks for registering for "\
        "#{@identity.user.institution.service_name}")
    assert_redirected_to @identity.user.institution.scope_url
  end

  test "update() updates the instance and sends an email if all arguments
  are valid" do
    @identity.create_registration_digest
    token    = @identity.registration_token
    name     = "New Name"
    password = LocalIdentity.random_password

    assert_emails 1 do
      patch local_identity_path(@identity),
            params: {
              token: token,
              honey_email: "",
              correct_answer_hash: Digest::MD5.hexdigest("5" + ApplicationHelper::CAPTCHA_SALT),
              answer: "5",
              local_identity: {
                password: password,
                password_confirmation: password,
                user_attributes: {
                  name: name
                }
              }
            }
      @identity.reload
      assert_nil @identity.registration_digest
      user = @identity.user
      assert_equal name, user.name
      assert_equal @institution, user.institution
      assert !user.institution_admin?(@institution)
    end
  end

  test "update() makes the user an institution administrator if directed to by
  the Invitee instance" do
    @identity.user.invitee.update!(institution_admin: true)
    @identity.create_registration_digest
    token    = @identity.registration_token
    name     = "New Name"
    password = LocalIdentity.random_password

    patch local_identity_path(@identity),
          params: {
            token: token,
            honey_email: "",
            correct_answer_hash: Digest::MD5.hexdigest("5" + ApplicationHelper::CAPTCHA_SALT),
            answer: "5",
            local_identity: {
              password: password,
              password_confirmation: password,
              user_attributes: {
                name: name
              }
            }
          }
    @identity.reload
    user = @identity.user
    assert user.institution_admin?(@institution)
  end

  # update_password()

  test "update_password() returns HTTP 404 for unscoped requests" do
    host! ::Configuration.instance.main_host
    @identity = local_identities(:southwest_sysadmin)
    patch local_identity_update_password_path(@identity), xhr: true
    assert_response :not_found
  end

  test "update_password() returns HTTP 403 for logged-out users" do
    @identity = local_identities(:southwest_sysadmin)
    patch local_identity_update_password_path(@identity), xhr: true
    assert_response :forbidden
  end

  test "update_password() returns HTTP 403 for unauthorized users" do
    log_in_as(users(:southwest))
    @identity = local_identities(:southwest_sysadmin)
    patch local_identity_update_password_path(@identity), xhr: true
    assert_response :forbidden
  end

  test "update_password() returns HTTP 400 if the current password is not
  supplied" do
    log_in_as(users(:southwest))
    password = LocalIdentity.random_password
    patch local_identity_update_password_path(@identity),
          xhr: true,
          params: {
            local_identity: {
              password:              password,
              password_confirmation: password
            }
          }
    assert_response :bad_request
  end

  test "update_password() returns HTTP 400 if the current password is
  incorrect" do
    log_in_as(users(:southwest))
    password = LocalIdentity.random_password
    patch local_identity_update_password_path(@identity),
          xhr: true,
          params: {
            current_password: "bogus",
            local_identity: {
              password:              password,
              password_confirmation: password
            }
          }
    assert_response :bad_request
  end

  test "update_password() returns HTTP 400 if the new password does not match
  the confirmation" do
    log_in_as(users(:southwest))
    patch local_identity_update_password_path(@identity),
          xhr: true,
          params: {
            current_password: "password",
            local_identity: {
              password:              "MyNewPassword123!",
              password_confirmation: "wrong"
            }
          }
    assert_response :bad_request
  end

  test "update_password() updates the password and returns HTTP 200" do
    log_in_as(users(:southwest))
    password = LocalIdentity.random_password
    patch local_identity_update_password_path(@identity),
          xhr: true,
          params: {
              current_password: "password",
              local_identity: {
                  password:              password,
                  password_confirmation: password
              }
          }
    assert_response :ok
    @identity.reload
    assert @identity.authenticated?(:password, password)
  end

  test "update_password() returns HTTP 404 for nonexistent identities" do
    log_in_as(users(:southwest_admin))
    patch "/identities/99999999/update-password", xhr: true
    assert_response :not_found
  end

end
