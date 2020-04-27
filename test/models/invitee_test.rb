require "test_helper"

class InviteeTest < ActiveSupport::TestCase

  setup do
    @instance = invitees(:norights)
    assert @instance.valid?
  end

  # create()

  test "create() creates an associated Identity" do
    email = "new@example.edu"
    assert_nil LocalIdentity.find_by_email(email)

    Invitee.create!(email: email)
    assert_not_nil LocalIdentity.find_by_email(email)
  end

  # destroy()

  test "destroy() destroys any associated Identity" do
    assert_not_nil @instance.identity
    @instance.destroy
    assert_nil LocalIdentity.find_by_email(@instance.email)
  end

  test "destroy() destroys any associated LocalUser" do
    assert_not_nil @instance.identity
    @instance.destroy
    assert_nil User.find_by_email(@instance.email)
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

  # identity()

  test "identity() returns an associated instance" do
    assert_not_nil @instance.identity
  end

  # user()

  test "user() returns an associated instance" do
    assert_not_nil @instance.user
  end

end
