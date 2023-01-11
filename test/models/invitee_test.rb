require "test_helper"

class InviteeTest < ActiveSupport::TestCase

  include ActionMailer::TestHelper

  class ApprovalStateTest < ActiveSupport::TestCase

    test "all() returns all approval states" do
      assert_equal Set.new(%w(approved rejected pending)),
                   Set.new(Invitee::ApprovalState.all)
    end

  end

  setup do
    @instance = invitees(:example)
    assert @instance.valid?
  end

  # create()

  test "create() sets approval_state" do
    invitee = Invitee.create!(email: "new@example.org",
                              note: "New note")
    assert_equal Invitee::ApprovalState::PENDING, invitee.approval_state
  end

  test "create() sets expires_at" do
    invitee = Invitee.create!(email: "new@example.org",
                              note: "New note")
    assert invitee.expires_at - Invitee::EXPIRATION - Time.now < 10.seconds
  end

  # approve()

  test "approve() updates the approval state" do
    @instance = invitees(:example_pending)
    @instance.approve
    assert_equal Invitee::ApprovalState::APPROVED, @instance.approval_state
  end

  test "approve() sends an email" do
    @instance = invitees(:example_pending)
    assert_emails 1 do
      @instance.approve
    end
  end

  # approved?()

  test "approved?() returns false if approval_state is not set to approved" do
    @instance.approval_state = Invitee::ApprovalState::PENDING
    assert !@instance.approved?
  end

  test "approved?() returns true if approval_state is set to approved" do
    @instance.approval_state = Invitee::ApprovalState::APPROVED
    assert @instance.approved?
  end

  # destroy()

  test "destroy() destroys any associated Identity" do
    assert_not_nil @instance.identity
    @instance.destroy!
    assert_nil LocalIdentity.find_by_email(@instance.email)
  end

  test "destroy() destroys any associated LocalUser" do
    assert_not_nil @instance.identity
    @instance.destroy!
    assert_nil LocalUser.find_by_email(@instance.email)
  end

  # email

  test "email is required" do
    @instance.email = nil
    assert !@instance.valid?

    @instance.email = ""
    assert !@instance.valid?
  end

  test "email must be unique" do
    assert_raises ActiveRecord::RecordInvalid do
      Invitee.create!(email: @instance.email)
    end
  end

  test "UofI email addresses are invalid" do
    assert_raises ActiveRecord::RecordInvalid do
      Invitee.create!(email: "newuser@illinois.edu")
    end
  end

  # expired?()

  test "expired?() returns true for an expired instance" do
    @instance.expires_at = 2.years.ago
    assert @instance.expired?
  end

  test "expired?() returns false for a non-expired instance" do
    @instance.expires_at = 6.months.ago
    assert !@instance.expired?
  end

  test "expired?() returns false when expires_at is nil" do
    @instance.expires_at = nil
    assert !@instance.expired?
  end

  # invite()

  test "invite() updates the approval state" do
    @instance = invitees(:example_pending)
    @instance.invite
    assert_equal Invitee::ApprovalState::APPROVED, @instance.approval_state
  end

  test "invite() sends an email" do
    @instance = invitees(:example_pending)
    assert_emails 1 do
      @instance.invite
    end
  end

  # note

  test "note is required" do
    @instance.note = nil
    assert !@instance.valid?

    @instance.note = ""
    assert !@instance.valid?
  end

  # pending?()

  test "pending?() returns false if approval_state is not set to pending" do
    @instance.approval_state = Invitee::ApprovalState::APPROVED
    assert !@instance.pending?
  end

  test "pending?() returns true if approval_state is set to pending" do
    @instance.approval_state = Invitee::ApprovalState::PENDING
    assert @instance.pending?
  end

  # reject()

  test "reject() updates the approval state" do
    @instance = invitees(:example_pending)
    @instance.reject
    assert_equal Invitee::ApprovalState::REJECTED, @instance.approval_state
  end

  test "reject() sends an email" do
    @instance = invitees(:example_pending)
    assert_emails 1 do
      @instance.reject
    end
  end

  # rejected?()

  test "rejected?() returns false if approval_state is not set to rejected" do
    @instance.approval_state = Invitee::ApprovalState::PENDING
    assert !@instance.rejected?
  end

  test "rejected?() returns true if approval_state is set to rejected" do
    @instance.approval_state = Invitee::ApprovalState::REJECTED
    assert @instance.rejected?
  end

  # send_approval_email()

  test "send_approval_email() raises an error if the instance is not approved" do
    @instance.approval_state = Invitee::ApprovalState::PENDING
    assert_no_emails do
      assert_raises do
        @instance.send_approval_email
      end
    end
  end

  test "send_approval_email() sends an email if the instance is approved" do
    @instance.approval_state = Invitee::ApprovalState::APPROVED
    assert_emails 1 do
      @instance.send_approval_email
    end
  end

  # send_invited_email()

  test "send_invited_email() raises an error if the instance is not approved" do
    @instance.approval_state = Invitee::ApprovalState::PENDING
    assert_no_emails do
      assert_raises do
        @instance.send_invited_email
      end
    end
  end

  test "send_invited_email() sends an email if the instance is approved" do
    @instance.approval_state = Invitee::ApprovalState::APPROVED
    assert_emails 1 do
      @instance.send_invited_email
    end
  end

  # send_reception_emails()

  test "send_reception_email() raises an error if the instance is not pending" do
    @instance.approval_state = Invitee::ApprovalState::APPROVED
    assert_no_emails do
      assert_raises do
        @instance.send_reception_emails
      end
    end
  end

  test "send_reception_email() sends two emails if the instance is pending" do
    @instance.approval_state = Invitee::ApprovalState::PENDING
    assert_emails 2 do
      @instance.send_reception_emails
    end
  end

  # send_rejection_email()

  test "send_rejection_email() raises an error if the instance is not rejected" do
    @instance.approval_state = Invitee::ApprovalState::PENDING
    assert_no_emails do
      assert_raises do
        @instance.send_rejection_email
      end
    end
  end

  test "send_rejection_email() sends an email if the instance is rejected" do
    @instance.approval_state = Invitee::ApprovalState::REJECTED
    assert_emails 1 do
      @instance.send_rejection_email
    end
  end

end
