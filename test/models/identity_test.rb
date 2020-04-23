require 'test_helper'

class IdentityTest < ActiveSupport::TestCase

  setup do
    @instance = identities(:norights)
  end

  # create_for_user()

  test "create_for_user() creates a correct instance" do
    user = User.create!(username: "joe", name: "Joe", email: "joe@example.org")
    identity = Identity.create_for_user(user, "password")
    assert identity.activated
    assert_equal user.name, identity.name
    assert_not_nil identity.password_digest
    assert_not_nil identity.password_confirmation
    assert_not_nil identity.activated_at
  end

  # new_token()

  test "new_token() returns a token" do
    assert_not_empty Identity.new_token
  end

  # uofi?()

  test "uofi?() returns true for UofI email addresses" do
    assert Identity.uofi?("test@illinois.edu")
    assert Identity.uofi?("test@uillinois.edu")
    assert Identity.uofi?("test@uiuc.edu")
    assert Identity.uofi?("TEST@UIUC.EDU")
  end

  test "uofi?() returns false for non-UofI email addresses" do
    assert !Identity.uofi?("test@example.org")
    assert !Identity.uofi?("test@not-illinois.edu")
  end

  test "uofi?() returns false for malformed email addresses" do
    assert !Identity.uofi?("not an email address")
  end

  # activation_url()

  test "activation_url() returns a correct URL" do
    base_url = ::Configuration.instance.website[:base_url].chomp("/")
    expected = "#{base_url}/account_activations/#{@instance.activation_token}/edit?email=#{CGI.escape(@instance.email)}"
    assert_equal expected, @instance.activation_url
  end

  # password_reset_url()

  test "password_reset_url raises an error if reset_token is blank" do
    assert_raises RuntimeError do
      @instance.password_reset_url
    end
  end

  test "password_reset_url() returns a correct URL" do
    @instance.create_reset_digest
    base_url = ::Configuration.instance.website[:base_url].chomp("/")
    expected = "#{base_url}/identities/#{@instance.id}/reset-password?token=#{@instance.reset_token}"
    assert_equal expected, @instance.password_reset_url
  end

  # update_password!()

  test "update_password!() raises an error if the confirmation does not match
  the password" do
    assert_raises ActiveRecord::RecordInvalid do
      @instance.update_password!(password: "MyNewPassword123",
                                 confirmation: "DoesNotMatch123")
    end
  end

  test "update_password!() updates the password" do
    digest   = @instance.password_digest
    new_password = "MyNewPassword123"
    @instance.update_password!(password: new_password,
                               confirmation: new_password)
    assert_not_equal digest, @instance.password_digest
  end

  test "update_password!() clears reset information" do
    new_password = "MyNewPassword123"
    @instance.update_password!(password: new_password,
                               confirmation: new_password)
    assert_nil @instance.reset_digest
    assert_nil @instance.reset_sent_at
  end

end
