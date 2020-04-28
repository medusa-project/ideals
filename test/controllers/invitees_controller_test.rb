require 'test_helper'

class InviteesControllerTest < ActionDispatch::IntegrationTest

  # create()

  test "create() via non-XHR redirects for illegal arguments" do
    log_in_as(users(:admin))

    post invitees_path, {
        params: {
            invitee: {
                email: "",
                note: "This is a new invitee"
            }
        }
    }
    assert_redirected_to new_invitee_path
  end

  test "create() via XHR returns HTTP 400 for illegal arguments" do
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

  test "create() sets the flash if all arguments are valid" do
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
  end

  test "create() via non-XHR redirects if all arguments are valid" do
    log_in_as(users(:admin))

    post invitees_path, {
        params: {
            invitee: {
                email: "new@example.edu",
                note: "This is a new invitee"
            }
        }
    }
    assert_redirected_to root_url
  end

  test "create() via XHR returns HTTP 200 if all arguments are valid" do
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
    assert_response :ok
  end

  # index()

  test "index() redirects to login page for logged-out users" do
    get invitees_path
    assert_redirected_to login_path
  end

  test "index() returns HTTP 403 for unauthorized users" do
    log_in_as(users(:norights))
    get invitees_path
    assert_response :forbidden
  end

  test "index() returns HTTP 200 for authorized users" do
    log_in_as(users(:admin))
    get invitees_path
    assert_response :ok
  end

  test "index() respects role limits" do
    log_in_as(users(:admin))
    get invitees_path
    assert_response :ok

    get invitees_path(role: Role::LOGGED_OUT)
    assert_response :forbidden
  end

  # new()

  test "new() redirects to root path for logged-in users" do
    log_in_as(users(:norights))
    get new_invitee_path
    assert_redirected_to root_path
  end

  test "new() returns HTTP 200 for logged-out users" do
    get new_invitee_path
    assert_response :ok
  end

end
