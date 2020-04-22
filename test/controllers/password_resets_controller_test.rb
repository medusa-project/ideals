require 'test_helper'

class PasswordResetsControllerTest < ActionDispatch::IntegrationTest

  # create()

  test "create() sets the flash and returns HTTP 400 when no email is provided" do
    # case 1
    post password_resets_path, {
        params: {}
    }
    assert_response :bad_request
    assert flash['error'].start_with?("No email address was provided")

    # case 2
    post password_resets_path, {
        params: {
            password_reset: {}
        }
    }
    assert_response :bad_request
    assert flash['error'].start_with?("No email address was provided")

    # case 3
    post password_resets_path, {
        params: {
            password_reset: {
                email: ""
            }
        }
    }
    assert_response :bad_request
    assert flash['error'].start_with?("No email address was provided")
  end

  test "create() sets the flash and returns HTTP 400 when an invalid email is provided" do
    post password_resets_path, {
        params: {
            password_reset: {
                email: "invalid email"
            }
        }
    }
    assert_response :bad_request
    assert flash['error'].start_with?("The email address you provided is invalid")
  end

  test "create() sets the flash and redirects when a UofI email is provided" do
    post password_resets_path, {
        params: {
            password_reset: {
                email: "user@illinois.edu"
            }
        }
    }
    assert_redirected_to root_url
    assert flash['error'].start_with?("Sorry, we're not able to reset")
  end

  test "create() sets the flash and redirects when an unregistered email is provided" do
    post password_resets_path, {
        params: {
            password_reset: {
                email: "unregistered@example.org"
            }
        }
    }
    assert_redirected_to new_password_reset_path
    assert flash['error'].start_with?("No user with this email")
  end

  test "create() creates a reset digest, sends an email, sets the flash,
  and redirects when a registered email is provided" do
    # We need to fetch an Identity and update its email to a non-UofI address,
    # but the process is a little bit convoluted.
    email = "norights@example.edu"
    Invitee.create!(email: email, expires_at: Time.now + 1.hour)
    identity = identities(:norights)
    identity.update!(email: email, password: "password")

    assert_no_emails
    post password_resets_path, {
        params: {
            password_reset: {
                email: email
            }
        }
    }
    identity.reload
    assert_not_nil identity.reset_digest
    assert Time.zone.now - identity.reset_sent_at < 10
    assert_emails 1
    assert flash['success'].start_with?("An email has been sent")
    assert_redirected_to root_url
  end

  # new()

  test "new() returns HTTP 200" do
    get new_password_reset_path
    assert_response :ok
  end

end
