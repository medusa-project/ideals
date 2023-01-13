require "test_helper"

##
# Tests that a new user can create an account.
#
class UserRegistrationTest < ActionDispatch::IntegrationTest

  setup do
    @institution = institutions(:southwest)
    host! @institution.fqdn
  end

  test "user can request an account" do
    get new_invitee_path
    assert_emails 2 do
      post create_unsolicited_invitees_path, params: {
        honey_email: "",
        correct_answer_hash: Digest::MD5.hexdigest("5" + ApplicationHelper::CAPTCHA_SALT),
        answer: "5",
        invitee: {
          email: "newuser@example.org",
          note:  "Testing"
        }
      }
      assert ActionMailer::Base.deliveries[0].text_part.body.include?("Thanks for requesting an account with IDEALS")
      assert ActionMailer::Base.deliveries[1].text_part.body.include?("A new user has requested to register for IDEALS")
      assert_redirected_to @institution.scope_url
    end
  end

end