require 'test_helper'

class IdealsMailerTest < ActionMailer::TestCase

  tests IdealsMailer

  # account_approved()

  test "account_approved() sends the expected email" do
    identity = local_identities(:example)
    identity.create_registration_digest

    email = IdealsMailer.account_approved(identity).deliver_now
    assert !ActionMailer::Base.deliveries.empty?

    assert_equal [IdealsMailer::NO_REPLY_ADDRESS], email.from
    assert_equal [identity.email], email.to
    assert_equal "Register your IDEALS account", email.subject

    assert_equal render_template("account_approved.txt",
                                 url: identity.registration_url),
                 email.text_part.body.raw_source
    assert_equal render_template("account_approved.html",
                                 url: identity.registration_url),
                 email.html_part.body.raw_source
  end

  # account_denied()

  test "account_denied() sends the expected email" do
    invitee = invitees(:example_pending)

    email = IdealsMailer.account_denied(invitee).deliver_now
    assert !ActionMailer::Base.deliveries.empty?

    assert_equal [IdealsMailer::NO_REPLY_ADDRESS], email.from
    assert_equal [invitee.email], email.to
    assert_equal "Your IDEALS account request", email.subject

    assert_equal render_template("account_denied.txt"),
                 email.text_part.body.raw_source
    assert_equal render_template("account_denied.html"),
                 email.html_part.body.raw_source
  end

  # account_registered()

  test "account_registered() sends the expected email" do
    identity    = local_identities(:example)
    institution = identity.invitee.institution

    email = IdealsMailer.account_registered(identity).deliver_now
    assert !ActionMailer::Base.deliveries.empty?

    assert_equal [IdealsMailer::NO_REPLY_ADDRESS], email.from
    assert_equal [identity.email], email.to
    assert_equal "Welcome to IDEALS!", email.subject

    assert_equal render_template("account_registered.txt",
                                 service_name: institution.service_name,
                                 url:          institution.scope_url),
                 email.text_part.body.raw_source
    assert_equal render_template("account_registered.html",
                                 service_name: institution.service_name,
                                 url:          institution.scope_url),
                 email.html_part.body.raw_source
  end

  # account_request_action_required()

  test "account_request_action_required() sends the expected email" do
    invitee     = invitees(:example_pending)
    institution = institutions(:example)

    email = IdealsMailer.account_request_action_required(invitee).deliver_now
    assert !ActionMailer::Base.deliveries.empty?

    assert_equal [IdealsMailer::NO_REPLY_ADDRESS], email.from
    assert_equal [institution.feedback_email], email.to
    assert_equal "[TEST: IDEALS] Action required on a new IDEALS user",
                 email.subject

    invitee_url = sprintf("https://%s/invitees/%d",
                          institution.fqdn,
                          invitee.id)
    assert_equal render_template("account_request_action_required.txt", url: invitee_url),
                 email.text_part.body.raw_source
    assert_equal render_template("account_request_action_required.html", url: invitee_url),
                 email.html_part.body.raw_source
  end

  # account_request_received()

  test "account_request_received() sends the expected email" do
    invitee = invitees(:example_pending)

    email = IdealsMailer.account_request_received(invitee).deliver_now
    assert !ActionMailer::Base.deliveries.empty?

    assert_equal [IdealsMailer::NO_REPLY_ADDRESS], email.from
    assert_equal [invitee.email], email.to
    assert_equal "Your IDEALS account request", email.subject

    assert_equal render_template("account_request_received.txt"),
                 email.text_part.body.raw_source
    assert_equal render_template("account_request_received.html"),
                 email.html_part.body.raw_source
  end

  # error()

  test "error() sends the expected email" do
    email = IdealsMailer.error("Something broke").deliver_now
    assert !ActionMailer::Base.deliveries.empty?

    config = ::Configuration.instance
    assert_equal [IdealsMailer::NO_REPLY_ADDRESS], email.from
    assert_equal config.admin[:tech_mail_list], email.to
    assert_equal "[TEST: IDEALS] System Error", email.subject
    assert_equal "Something broke\r\n\r\n", email.body.raw_source
  end

  # invited()

  test "invited() sends the expected email" do
    identity = local_identities(:example)
    identity.create_registration_digest

    email = IdealsMailer.invited(identity).deliver_now
    assert !ActionMailer::Base.deliveries.empty?

    assert_equal [IdealsMailer::NO_REPLY_ADDRESS], email.from
    assert_equal [identity.email], email.to
    assert_equal "Register for an account with IDEALS", email.subject

    assert_equal render_template("invited.txt", url: identity.registration_url),
                 email.text_part.body.raw_source
    assert_equal render_template("invited.html", url: identity.registration_url),
                 email.html_part.body.raw_source
  end

  # item_submitted()

  test "item_submitted() sends the expected email" do
    item  = items(:uiuc_submitted)
    email = IdealsMailer.item_submitted(item).deliver_now
    assert !ActionMailer::Base.deliveries.empty?

    assert_equal [IdealsMailer::NO_REPLY_ADDRESS], email.from
    assert email.to.length > 1
    assert_equal "A new IDEALS item requires review", email.subject

    assert_equal render_template("item_submitted.txt",
                                 item_url: "#{item.institution.scope_url}/items/#{item.id}"),
                 email.text_part.body.raw_source
    assert_equal render_template("item_submitted.html",
                                 item_url: "#{item.institution.scope_url}/items/#{item.id}"),
                 email.html_part.body.raw_source
  end

  # password_reset()

  test "password_reset() sends the expected email" do
    identity = local_identities(:example)
    identity.create_reset_digest

    email = IdealsMailer.password_reset(identity).deliver_now
    assert !ActionMailer::Base.deliveries.empty?

    assert_equal [IdealsMailer::NO_REPLY_ADDRESS], email.from
    assert_equal [identity.email], email.to
    assert_equal "Reset your IDEALS password", email.subject

    assert_equal render_template("password_reset.txt",
                                 url: identity.password_reset_url),
                 email.text_part.body.raw_source
    assert_equal render_template("password_reset.html",
                                 url: identity.password_reset_url),
                 email.html_part.body.raw_source
  end

  # test()

  test "test() sends the expected email" do
    recipient = "user@example.edu"
    email = IdealsMailer.test(recipient).deliver_now
    assert !ActionMailer::Base.deliveries.empty?

    assert_equal [IdealsMailer::NO_REPLY_ADDRESS], email.from
    assert_equal [recipient], email.to
    assert_equal "[TEST: IDEALS] Hello from IDEALS", email.subject

    assert_equal render_template("test.txt"), email.text_part.body.raw_source
    assert_equal render_template("test.html"), email.html_part.body.raw_source
  end

  private

  def render_template(fixture_name, vars = {})
    text = read_fixture(fixture_name).join
    vars.each do |k, v|
      text.gsub!("{{{#{k}}}}", v)
    end
    text
  end

end
