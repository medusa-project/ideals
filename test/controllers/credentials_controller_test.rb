require 'test_helper'

class CredentialsControllerTest < ActionDispatch::IntegrationTest

  setup do
    @institution = institutions(:southwest)
    host! @institution.fqdn
    @credential = credentials(:southwest)
  end

  # create()

  test "create() returns HTTP 404 for unscoped requests" do
    host! ::Configuration.instance.main_host
    user = users(:southwest_sysadmin)
    user.credential.destroy!
    post user_credentials_path(user)
    assert_response :not_found
  end

  test "create() redirects to root page for logged-out users" do
    user = users(:southwest_sysadmin)
    user.credential.destroy!
    post user_credentials_path(user)
    assert_redirected_to @credential.user.institution.scope_url
  end

  test "create() returns HTTP 403 for unauthorized users" do
    user = users(:southwest_sysadmin)
    user.credential.destroy!
    log_in_as(user)
    post user_credentials_path(user),
         xhr: true,
         params: {
           credential: {
             password:              "MyNewPassword123!",
             password_confirmation: "MyNewPassword123!"
           }
         }
    assert_response :forbidden
  end

  test "create() returns HTTP 200" do
    user = users(:southwest_sysadmin)
    log_in_as(user)
    user.credential.destroy! # do this after logging in, otherwise we wouldn't be able to
    post user_credentials_path(user),
         xhr: true,
         params: {
           credential: {
             password:              "MyNewPassword123!",
             password_confirmation: "MyNewPassword123!"
           }
         }
    assert_response :ok
  end

  test "create() creates a Credential" do
    user = users(:southwest_sysadmin)
    log_in_as(user)
    user.credential.destroy! # do this after logging in, otherwise we wouldn't be able to
    assert_difference "Credential.count" do
      post user_credentials_path(user),
           xhr: true,
           params: {
             credential: {
               password:              "MyNewPassword123!",
               password_confirmation: "MyNewPassword123!"
             }
           }
    end
  end

  test "create() returns HTTP 400 for illegal arguments" do
    user = users(:southwest_sysadmin)
    log_in_as(user)
    post user_credentials_path(user),
         xhr: true,
         params: {
           credential: {
             password:              "MyNewPassword123!",
             password_confirmation: "DoesNotMatch123!"
           }
         }
    assert_response :bad_request
  end

  # edit_password()

  test "edit_password() returns HTTP 404 for unscoped requests" do
    host! ::Configuration.instance.main_host
    @credential = credentials(:southwest_sysadmin)
    get credential_edit_password_path(@credential), xhr: true
    assert_response :not_found
  end

  test "edit_password() returns HTTP 403 for logged-out users" do
    @credential = credentials(:southwest_sysadmin)
    get credential_edit_password_path(@credential), xhr: true
    assert_response :forbidden
  end

  test "edit_password() returns HTTP 403 for unauthorized users" do
    log_in_as(users(:southwest))
    @credential = credentials(:southwest_admin)
    get credential_edit_password_path(@credential), xhr: true
    assert_response :forbidden
  end

  test "edit_password() returns HTTP 403 for users other than the user whose
  password is being changed" do
    log_in_as(users(:southwest_sysadmin))
    get credential_edit_password_path(@credential), xhr: true
    assert_response :forbidden
  end

  test "edit_password() returns HTTP 200 for authorized users" do
    log_in_as(users(:southwest))
    get credential_edit_password_path(@credential), xhr: true
    assert_response :ok
  end

  test "edit_password() respects role limits" do
    log_in_as(users(:southwest_sysadmin))
    @credential = credentials(:southwest_sysadmin)
    get credential_edit_password_path(@credential), xhr: true
    assert_response :ok

    get credential_edit_password_path(@credential,
                                          role: Role::LOGGED_OUT), xhr: true
    assert_response :forbidden
  end

  # new()

  test "new() returns HTTP 404 for unscoped requests" do
    host! ::Configuration.instance.main_host
    get new_user_credential_path(@credential.user)
    assert_response :not_found
  end

  test "new() redirects to root page for logged-out users" do
    get new_user_credential_path(@credential.user)
    assert_redirected_to @credential.user.institution.scope_url
  end

  test "new() returns HTTP 403 for unauthorized users" do
    log_in_as(users(:southwest))
    get new_user_credential_path(@credential.user)
    assert_response :forbidden
  end

  test "new() returns HTTP 200 for authorized users" do
    log_in_as(users(:southwest_sysadmin))
    get new_user_credential_path(@credential.user)
    assert_response :ok
  end

  # new_password()

  test "new_password() returns HTTP 404 for unscoped requests" do
    host! ::Configuration.instance.main_host
    get credential_reset_password_path(@credential)
    assert_response :not_found
  end

  test "new_password() redirects to root path for logged-in users" do
    get credential_reset_password_path(@credential)
    assert_redirected_to root_path
  end

  test "new_password() redirects and sets the flash if a token is not provided" do
    get credential_reset_password_path(@credential)
    assert_equal "Invalid password reset link.", flash['error']
    assert_redirected_to root_url
  end

  test "new_password() redirects and sets the flash if an invalid token is
  provided" do
    get credential_reset_password_path(@credential, token: "bogus")
    assert_equal "Invalid password reset link.", flash['error']
    assert_redirected_to root_url
  end

  test "new_password() redirects and sets the flash if an expired token is
  provided" do
    @credential.create_reset_digest
    token = @credential.reset_token
    @credential.update_attribute(:reset_sent_at, Time.now - 1.month)

    get credential_reset_password_path(@credential, token: token)
    assert_equal "This password reset link has expired. Please try again.",
                 flash['error']
    assert_redirected_to reset_password_url
  end

  test "new_password() returns HTTP 200 if a valid token is provided" do
    @credential.create_reset_digest
    token = @credential.reset_token

    get credential_reset_password_path(@credential, token: token)
    assert_response :ok
  end

  # register()

  test "register() returns HTTP 404 for unscoped requests" do
    host! ::Configuration.instance.main_host
    get credential_register_path(@credential)
    assert_response :not_found
  end

  test "register() redirects to root path for logged-in users" do
    get credential_register_path(@credential)
    assert_redirected_to root_path
  end

  test "register() redirects and sets the flash if a token is not provided" do
    @credential.create_registration_digest
    get credential_register_path(@credential)
    assert_equal "Invalid registration link.", flash['error']
    assert_redirected_to root_url
  end

  test "register() redirects and sets the flash if an invalid token is
  provided" do
    @credential.create_registration_digest
    get credential_register_path(@credential, token: "bogus")
    assert_equal "Invalid registration link.", flash['error']
    assert_redirected_to root_url
  end

  test "register() returns HTTP 200 if a valid token is provided" do
    @credential.create_registration_digest
    token = @credential.registration_token

    get credential_register_path(@credential, token: token)
    assert_response :ok
  end

  # reset_password()

  test "reset_password() returns HTTP 404 for unscoped requests" do
    host! ::Configuration.instance.main_host
    post credential_reset_password_path(@credential)
    assert_response :not_found
  end

  test "reset_password() redirects to root path for logged-in users" do
    post credential_reset_password_path(@credential)
    assert_redirected_to root_path
  end

  test "reset_password() redirects and sets the flash if a token is not
  provided" do
    post credential_reset_password_path(@credential),
         params: {
           credential: {
             password: "MyNewPassword123!",
             password_confirmation: "MyNewPassword123!"
           }
         }
    assert_equal "Invalid password reset link.", flash['error']
    assert_redirected_to root_url
  end

  test "reset_password() redirects and sets the flash if an invalid token is
  provided" do
    post credential_reset_password_path(@credential),
         params: {
           token: "bogus",
           credential: {
             password: "MyNewPassword123!",
             password_confirmation: "MyNewPassword123!"
           }
         }
    assert_equal "Invalid password reset link.", flash['error']
    assert_redirected_to root_url
  end

  test "reset_password() redirects and sets the flash if an expired token is
  provided" do
    @credential.create_reset_digest
    token = @credential.reset_token
    @credential.update_attribute(:reset_sent_at, Time.now - 1.month)

    post credential_reset_password_path(@credential),
         params: {
           token: token,
           credential: {
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
    @credential.create_reset_digest
    token = @credential.reset_token

    post credential_reset_password_path(@credential),
         params: {
           token: token,
           credential: {
             password:              Credential.random_password,
             password_confirmation: Credential.random_password
           }
         }
    assert flash['error'].include?("Password confirmation doesn't match")
  end

  test "reset_password() sets the flash and redirects if all arguments are
  valid" do
    @credential.create_reset_digest
    token    = @credential.reset_token
    password = Credential.random_password

    post credential_reset_password_path(@credential),
         params: {
           token: token,
           credential: {
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
    patch credential_path(@credential)
    assert_response :not_found
  end

  test "update() redirects to root path for logged-in users" do
    patch credential_path(@credential)
    assert_redirected_to root_path
  end

  test "update() sets the flash and redirects if no token is provided" do
    @credential.create_registration_digest
    patch credential_path(@credential),
          params: {
            honey_email: "",
            correct_answer_hash: Digest::MD5.hexdigest("5" + ApplicationHelper::CAPTCHA_SALT),
            answer: "5",
            credential: {
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
    @credential.update!(registration_digest: nil)
    token    = @credential.registration_token
    password = Credential.random_password

    patch credential_path(@credential),
          params: {
            token: token,
            honey_email: "",
            correct_answer_hash: Digest::MD5.hexdigest("5" + ApplicationHelper::CAPTCHA_SALT),
            answer: "5",
            credential: {
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
    @credential.create_registration_digest
    patch credential_path(@credential),
          params: {
            token: "bogus",
            honey_email: "",
            correct_answer_hash: Digest::MD5.hexdigest("5" + ApplicationHelper::CAPTCHA_SALT),
            answer: "5",
            credential: {
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
    @credential.create_registration_digest
    token = @credential.registration_token

    patch credential_path(@credential),
          params: {
            token: token,
            honey_email: "",
            correct_answer_hash: Digest::MD5.hexdigest("5" + ApplicationHelper::CAPTCHA_SALT),
            answer: "5",
            credential: {
              password: "MyNewPassword123!",
              password_confirmation: "ThisDoesNotMatch123!",
              user_attributes: {
                name: "New Name"
              }
            }
          }
    assert flash['error'].include?("Password confirmation doesn't match")
    assert_redirected_to credential_register_path(@credential, token: token)
  end

  test "update() sets the flash and redirects back upon an incorrect CAPTCHA
  response" do
    @credential.create_registration_digest
    token    = @credential.registration_token
    name     = "New Name"
    password = Credential.random_password

    patch credential_path(@credential),
          params: {
            token: token,
            honey_email: "",
            correct_answer_hash: Digest::MD5.hexdigest("5" + ApplicationHelper::CAPTCHA_SALT),
            answer: "7", # WRONG!
            credential: {
              password: password,
              password_confirmation: password,
              user_attributes: {
                name: name
              }
            }
          }
    assert flash['error'].start_with?("Incorrect math question response")
    assert_redirected_to credential_register_path(@credential, token: token)
  end

  test "update() sets the flash and redirects if all arguments are valid" do
    @credential.create_registration_digest
    token    = @credential.registration_token
    password = Credential.random_password

    patch credential_path(@credential),
          params: {
            token: token,
            honey_email: "",
            correct_answer_hash: Digest::MD5.hexdigest("5" + ApplicationHelper::CAPTCHA_SALT),
            answer: "5",
            credential: {
              password:              password,
              password_confirmation: password,
              user_attributes: {
                name: "New Name"
              }
            }
          }
    assert flash['success'].start_with?("Thanks for registering for "\
        "#{@credential.user.institution.service_name}")
    assert_redirected_to @credential.user.institution.scope_url
  end

  test "update() updates the instance and sends an email if all arguments
  are valid" do
    @credential.create_registration_digest
    token    = @credential.registration_token
    name     = "New Name"
    password = Credential.random_password

    assert_emails 1 do
      patch credential_path(@credential),
            params: {
              token: token,
              honey_email: "",
              correct_answer_hash: Digest::MD5.hexdigest("5" + ApplicationHelper::CAPTCHA_SALT),
              answer: "5",
              credential: {
                password: password,
                password_confirmation: password,
                user_attributes: {
                  name: name
                }
              }
            }
      @credential.reload
      assert_nil @credential.registration_digest
      user = @credential.user
      assert_equal name, user.name
      assert_equal @institution, user.institution
      assert !user.institution_admin?(@institution,
                                      client_ip:       "127.0.0.1",
                                      client_hostname: "localhost")
    end
  end

  test "update() makes the user an institution administrator if directed to by
  the Invitee instance" do
    @credential.user.invitee.update!(institution_admin: true)
    @credential.create_registration_digest
    token    = @credential.registration_token
    name     = "New Name"
    password = Credential.random_password

    patch credential_path(@credential),
          params: {
            token: token,
            honey_email: "",
            correct_answer_hash: Digest::MD5.hexdigest("5" + ApplicationHelper::CAPTCHA_SALT),
            answer: "5",
            credential: {
              password: password,
              password_confirmation: password,
              user_attributes: {
                name: name
              }
            }
          }
    @credential.reload
    user = @credential.user
    assert user.institution_admin?(@institution,
                                   client_ip:       "127.0.0.1",
                                   client_hostname: "localhost")
  end

  # update_password()

  test "update_password() returns HTTP 404 for unscoped requests" do
    host! ::Configuration.instance.main_host
    @credential = credentials(:southwest_sysadmin)
    patch credential_update_password_path(@credential), xhr: true
    assert_response :not_found
  end

  test "update_password() returns HTTP 403 for logged-out users" do
    @credential = credentials(:southwest_sysadmin)
    patch credential_update_password_path(@credential), xhr: true
    assert_response :forbidden
  end

  test "update_password() returns HTTP 403 for unauthorized users" do
    log_in_as(users(:southwest))
    @credential = credentials(:southwest_sysadmin)
    patch credential_update_password_path(@credential), xhr: true
    assert_response :forbidden
  end

  test "update_password() returns HTTP 400 if the current password is not
  supplied" do
    log_in_as(users(:southwest))
    password = Credential.random_password
    patch credential_update_password_path(@credential),
          xhr: true,
          params: {
            credential: {
              password:              password,
              password_confirmation: password
            }
          }
    assert_response :bad_request
  end

  test "update_password() returns HTTP 400 if the current password is
  incorrect" do
    log_in_as(users(:southwest))
    password = Credential.random_password
    patch credential_update_password_path(@credential),
          xhr: true,
          params: {
            current_password: "bogus",
            credential: {
              password:              password,
              password_confirmation: password
            }
          }
    assert_response :bad_request
  end

  test "update_password() returns HTTP 400 if the new password does not match
  the confirmation" do
    log_in_as(users(:southwest))
    patch credential_update_password_path(@credential),
          xhr: true,
          params: {
            current_password: "password",
            credential: {
              password:              "MyNewPassword123!",
              password_confirmation: "wrong"
            }
          }
    assert_response :bad_request
  end

  test "update_password() updates the password and returns HTTP 200" do
    log_in_as(users(:southwest))
    password = Credential.random_password
    patch credential_update_password_path(@credential),
          xhr: true,
          params: {
              current_password: "password",
              credential: {
                  password:              password,
                  password_confirmation: password
              }
          }
    assert_response :ok
    @credential.reload
    assert @credential.authenticated?(:password, password)
  end

  test "update_password() returns HTTP 404 for nonexistent credentials" do
    log_in_as(users(:southwest_admin))
    patch "/credentials/99999999/update-password", xhr: true
    assert_response :not_found
  end

end
