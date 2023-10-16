require "test_helper"

##
# Tests that a new user can create an account.
#
class UserRegistrationTest < ActionDispatch::IntegrationTest

  setup do
    @institution = institutions(:southwest)
    host! @institution.fqdn
  end

  teardown do
    log_out
  end

  test "user can request an account" do
    get new_invitee_path
    assert_emails 2 do
      request_unsolicited_invitee(email: "newuser@example.org")
      assert ActionMailer::Base.deliveries[0].subject.match?(/\AYour [\w\s]+ account request\z/)
      assert ActionMailer::Base.deliveries[1].subject.match?(/Action required on a new [\w\s]+ user\z/)
      assert_redirected_to @institution.scope_url
    end
  end

  test "user receives a registration email after account request is approved" do
    get new_invitee_path

    # User requests the account
    email = "newuser@example.org"
    request_unsolicited_invitee(email: email)

    # Administrator approves it
    ActionMailer::Base.deliveries.clear
    assert_emails 1 do
      approve(email: email)
      assert ActionMailer::Base.deliveries[0].subject.match?(/\ARegister your [\w\s]+ account\z/)
    end
  end

  test "user can register after account request is approved" do
    get new_invitee_path

    # User requests the account
    email = "newuser@example.org"
    request_unsolicited_invitee(email: email)
    ActionMailer::Base.deliveries.clear

    # Administrator approves it
    approve(email: email)
    assert ActionMailer::Base.deliveries[0].subject.match?(/\ARegister your [\w\s]+ account\z/)
    registration_url = ActionMailer::Base.deliveries[0].text_part.body.match(/(http:\/\/.*)/)[0]
    token            = registration_url.match(/token=(.*)\z/)[1]

    # Request the registration form
    get registration_url
    assert_response :ok

    # Fill it out and submit it
    ActionMailer::Base.deliveries.clear
    assert_emails 1 do
      submit_registration_form(email: email, token: token)
      assert ActionMailer::Base.deliveries[0].subject.match?(/\AWelcome to [\w\s]+!\z/)
    end

    # Log in
    user = User.find_by_email(email)
    assert user.enabled
    log_in_as(user)
  end


  private

  def request_unsolicited_invitee(email:)
    post create_unsolicited_invitees_path, params: {
      honey_email: "",
      correct_answer_hash: Digest::MD5.hexdigest("5" + ApplicationHelper::CAPTCHA_SALT),
      answer: "5",
      invitee: {
        email:   email,
        purpose: "Testing"
      }
    }
  end

  def approve(email:)
    log_in_as(users(:southwest_admin))
    invitee = Invitee.find_by_email(email)
    patch invitee_approve_path(invitee)
    log_out
  end

  def submit_registration_form(email:, token:)
    identity = LocalIdentity.find_by_email(email)
    patch local_identity_path(identity), params: {
      token: token,
      local_identity: {
        user_attributes: {
          name:  "New User",
          phone: "555-5555"
        },
        password:              "Password01!",
        password_confirmation: "Password01!"
      },
      # captcha fields
      honey_email:         "",
      correct_answer_hash: Digest::MD5.hexdigest("5" + ApplicationHelper::CAPTCHA_SALT),
      answer:              "5",
    }
  end

end