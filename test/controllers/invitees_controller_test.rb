require 'test_helper'

class InviteesControllerTest < ActionDispatch::IntegrationTest

  # create()

  test "create() redirects to login page for logged-out users" do
    post invitees_path, {}
    assert_redirected_to login_path
  end

  test "create() returns HTTP 403 for unauthorized users" do
    log_in_as(users(:norights))

    post invitees_path, {
        xhr: true,
        params: {
            invitee: {
                email: "new@example.edu",
                note: "This is a new invitee"
            }
        }
    }
    assert_response :forbidden
  end

  test "create() returns HTTP 400 for illegal arguments" do
    log_in_as(users(:admin))

    post invitees_path, {
        xhr: true,
        params: {
            invitee: {
                email: "",
                note: "This is a new invitee"
            }
        }
    }
    assert_response :bad_request
  end

  test "create() creates an instance and sends an email if all arguments are valid" do
    log_in_as(users(:admin))

    email = "new@example.edu"
    assert_nil Invitee.find_by_email(email)

    assert_emails 1 do
      post invitees_path, {
          xhr: true,
          params: {
              invitee: {
                  email: email,
                  note: "This is a new invitee"
              }
          }
      }
      assert_not_nil Invitee.find_by_email(email)
    end
  end

  test "create() sets the flash and returns HTTP 200 if all arguments are valid" do
    log_in_as(users(:admin))

    post invitees_path, {
        xhr: true,
        params: {
            invitee: {
                email: "new@example.edu",
                note: "This is a new invitee"
            }
        }
    }
    assert flash['success'].start_with?("An invitation has been sent")
    assert_response :ok
  end

  # new()

  test "new() returns HTTP 200 for logged-out users" do
    get new_invitee_path
    assert_response :ok
  end

end
