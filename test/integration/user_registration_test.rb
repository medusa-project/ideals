require "test_helper"

##
# Tests that a new user can create an account.
#
class UserRegistrationTest < ActionDispatch::IntegrationTest

  test "user can request an account" do
    get new_invitee_path
    assert_emails 2 do
      post create_unsolicited_invitees_path, params: {
        invitee: {
          email: "newuser@example.org",
          note:  "Testing"
        }
      }
      assert ActionMailer::Base.deliveries[0].text_part.body.include?("Thanks for requesting an IDEALS account")
      assert ActionMailer::Base.deliveries[1].text_part.body.include?("A new user has requested to register for IDEALS")
      assert_redirected_to root_path
    end
  end

end