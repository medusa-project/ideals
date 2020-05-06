require 'test_helper'

class PasswordResetsControllerTest < ActionDispatch::IntegrationTest

  # get()

  test "get() returns HTTP 200" do
    get reset_password_path
    assert_response :ok
  end

  # post()

  test "post() sets the flash and returns HTTP 400 when no email is provided" do
    # case 1
    post reset_password_path, params: {}
    assert_response :bad_request
    assert flash['error'].start_with?("No email address was provided")

    # case 2
    post reset_password_path,
         params: {
             password_reset: {}
         }
    assert_response :bad_request
    assert flash['error'].start_with?("No email address was provided")

    # case 3
    post reset_password_path,
         params: {
             password_reset: {
                 email: ""
             }
         }
    assert_response :bad_request
    assert flash['error'].start_with?("No email address was provided")
  end

  test "post() sets the flash and returns HTTP 400 when an invalid email is provided" do
    post reset_password_path,
         params: {
             password_reset: {
                 email: "invalid email"
             }
         }
    assert_response :bad_request
    assert flash['error'].start_with?("The email address you provided is invalid")
  end

  test "post() sets the flash and redirects when a UofI email is provided" do
    post reset_password_path,
         params: {
             password_reset: {
                 email: "user@illinois.edu"
             }
         }
    assert_redirected_to root_url
    assert flash['error'].start_with?("Sorry, we're not able to reset")
  end

  test "post() sets the flash and redirects when an unregistered email is provided" do
    post reset_password_path,
         params: {
             password_reset: {
                 email: "unregistered@example.org"
             }
         }
    assert_redirected_to reset_password_path
    assert flash['error'].start_with?("No user with this email")
  end

  test "post() posts a reset digest, sends an email, sets the flash,
  and redirects when a registered email is provided" do
    # We need to fetch an Identity and update its email to a non-UofI address,
    # but the process is a little bit convoluted.
    email    = "test@example.edu"
    password = "password"
    invitee  = Invitee.create!(email: email,
                               note: "Note",
                               expires_at: Time.now + 1.hour)
    invitee.send(:associate_or_create_identity)
    identity = invitee.identity
    identity.update!(email: email,
                     password: password,
                     password_confirmation: password)

    assert_emails 1 do
      post reset_password_path,
           params: {
               password_reset: {
                   email: email
               }
           }
    end
    identity.reload
    assert_not_nil identity.reset_digest
    assert Time.zone.now - identity.reset_sent_at < 10
    assert flash['success'].start_with?("An email has been sent")
    assert_redirected_to root_url
  end

end
