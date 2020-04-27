require 'test_helper'

class IdealsMailerTest < ActionMailer::TestCase

  tests IdealsMailer

  # account_activation()

  test "account_activation() sends the expected email" do
    identity = identities(:norights)
    identity.send(:create_activation_digest)

    email = IdealsMailer.account_activation(identity).deliver_now
    assert !ActionMailer::Base.deliveries.empty?

    assert_equal [Configuration.instance.mail[:from]], email.from
    assert_equal [identity.email], email.to
    assert_equal "Activate your IDEALS account", email.subject

    assert_equal render_template("account_activation.txt", url: identity.activation_url),
                 email.text_part.body.raw_source
    assert_equal render_template("account_activation.html", url: identity.activation_url),
                 email.html_part.body.raw_source
  end

  # error()

  test "error() sends the expected email" do
    email = IdealsMailer.error("Something broke").deliver_now
    assert !ActionMailer::Base.deliveries.empty?

    assert_equal [IdealsMailer::NO_REPLY_ADDRESS], email.reply_to
    assert_equal Configuration.instance.admin[:tech_mail_list], email.to
    assert_equal "[TEST: IDEALS] System Error", email.subject
    assert_equal "Something broke\r\n\r\n", email.body.raw_source
  end

  # password_reset()

  test "password_reset() sends the expected email" do
    identity = identities(:norights)
    identity.create_reset_digest

    email = IdealsMailer.password_reset(identity).deliver_now
    assert !ActionMailer::Base.deliveries.empty?

    assert_equal [Configuration.instance.mail[:from]], email.from
    assert_equal [identity.email], email.to
    assert_equal "Reset your IDEALS password", email.subject

    assert_equal render_template("password_reset.txt", url: identity.password_reset_url),
                 email.text_part.body.raw_source
    assert_equal render_template("password_reset.html", url: identity.password_reset_url),
                 email.html_part.body.raw_source
  end

  # password_reset()

  test "test() sends the expected email" do
    recipient = "user@example.edu"
    email = IdealsMailer.test(recipient).deliver_now
    assert !ActionMailer::Base.deliveries.empty?

    assert_equal [Configuration.instance.mail[:from]], email.from
    assert_equal [recipient], email.to
    assert_equal "Hello from IDEALS", email.subject

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
