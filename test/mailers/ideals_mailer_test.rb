require 'test_helper'

class IdealsMailerTest < ActionMailer::TestCase

  tests IdealsMailer

  test "error() sends the expected email" do
    email = IdealsMailer.error("Something broke").deliver_now
    assert !ActionMailer::Base.deliveries.empty?

    assert_equal [IdealsMailer::NO_REPLY_ADDRESS], email.from
    assert_equal Configuration.instance.admin[:tech_mail_list], email.to
    assert_equal "[LOCAL: IDEALS] System Error", email.subject
    assert_equal "Something broke\r\n\r\n", email.body.raw_source
  end

end
