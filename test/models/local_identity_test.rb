require 'test_helper'

class LocalIdentityTest < ActiveSupport::TestCase

  include ActionMailer::TestHelper

  setup do
    @instance = local_identities(:norights)
  end

  # create()

  test "create() does not allow association with an expired Invitee" do
    assert_raises ActiveRecord::RecordInvalid do
      # LocalIdentity.create() is invoked indirectly
      Invitee.create!(email: "test@example.org",
                      expires_at: 10.years.ago)
    end
  end

  # create_for_user()

  test "create_for_user() creates a correct instance" do
    user     = LocalUser.create!(uid:      "joe",
                                 name:     "Joe",
                                 email:    "joe@example.org")
    identity = LocalIdentity.create_for_user(user, "password")
    assert identity.activated
    assert_not_nil identity.password_digest
    assert_not_nil identity.password_confirmation
    assert_not_nil identity.activated_at
  end

  # new_token()

  test "new_token() returns a token" do
    assert_not_empty LocalIdentity.new_token
  end

  # activate()

  test "activate() activates the instance" do
    @instance.activated    = false
    @instance.activated_at = nil

    @instance.activate
    assert @instance.activated
    assert_not_nil @instance.activated_at
  end

  test "activate() clears the activation and registration digests" do
    @instance.create_registration_digest
    @instance.create_activation_digest

    @instance.activate
    assert_nil @instance.registration_digest
    assert_nil @instance.activation_digest
  end

  # activation_url()

  test "activation_url raises an error if activation_token is blank" do
    assert_raises RuntimeError do
      @instance.activation_url
    end
  end

  test "activation_url() returns a correct URL" do
    @instance.create_activation_digest
    base_url = ::Configuration.instance.website[:base_url].chomp("/")
    expected = "#{base_url}/identities/#{@instance.id}/activate?token=#{@instance.activation_token}"
    assert_equal expected, @instance.activation_url
  end

  # create_activation_digest()

  test "create_activation_digest() works" do
    digest  = @instance.activation_digest
    @instance.create_activation_digest

    assert_not_empty @instance.activation_digest
    assert_not_equal digest, @instance.activation_digest
  end

  test "create_activation_digest() clears the registration digest" do
    @instance.create_registration_digest
    @instance.create_activation_digest

    assert_nil @instance.registration_digest
  end

  # create_registration_digest()

  test "create_registration_digest() works" do
    digest  = @instance.registration_digest
    @instance.create_registration_digest

    assert_not_empty @instance.registration_digest
    assert_not_equal digest, @instance.registration_digest
  end

  # create_reset_digest()

  test "create_reset_digest() works" do
    digest  = @instance.reset_digest
    sent_at = @instance.reset_sent_at
    @instance.create_reset_digest

    assert_not_empty @instance.reset_digest
    assert_not_equal digest, @instance.reset_digest
    assert_not_nil @instance.reset_sent_at
    assert_not_equal sent_at, @instance.reset_sent_at
  end

  # destroy()

  test "destroy() destroys any associated LocalUser" do
    assert_not_nil @instance.user
    @instance.destroy!
    assert_nil LocalUser.find_by_email(@instance.email)
  end

  # invitee()

  test "invitee is required" do
    email    = "test@example.org"
    password = "password"
    assert_raises ActiveRecord::RecordInvalid do
      @instance = LocalIdentity.create!(email: email,
                                        password: password,
                                        password_confirmation: password)
    end
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

  # registration_url()

  test "registration_url raises an error if registration_token is blank" do
    assert_raises RuntimeError do
      @instance.registration_url
    end
  end

  test "registration_url() returns a correct URL" do
    @instance.create_registration_digest
    base_url = ::Configuration.instance.website[:base_url].chomp("/")
    expected = "#{base_url}/identities/#{@instance.id}/register?token=#{@instance.registration_token}"
    assert_equal expected, @instance.registration_url
  end

  # send_approval_email()

  test "send_approval_email() raises an error if registration_token is not set" do
    assert_no_emails do
      assert_raises do
        @instance.send_approval_email
      end
    end
  end

  test "send_approval_email() sends an email if registration_token is set" do
    @instance.create_registration_digest
    assert_emails 1 do
      @instance.send_approval_email
    end
  end

  # send_invited_email()

  test "send_invited_email() raises an error if registration_token is not set" do
    assert_no_emails do
      assert_raises do
        @instance.send_invited_email
      end
    end
  end

  test "send_invited_email() sends an email if registration_token is set" do
    @instance.create_registration_digest
    assert_emails 1 do
      @instance.send_invited_email
    end
  end

  # send_password_reset_email()

  test "send_password_reset_email() raises an error if reset_token is not set" do
    assert_no_emails do
      assert_raises do
        @instance.send_password_reset_email
      end
    end
  end

  test "send_password_reset_email() sends an email if reset_token is set" do
    @instance.create_reset_digest
    assert_emails 1 do
      @instance.send_password_reset_email
    end
  end

  # send_post_registration_email()

  test "send_post_registration_email() sends an email" do
    @instance.create_activation_digest
    assert_emails 1 do
      @instance.send_post_registration_email
    end
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
    digest       = @instance.password_digest
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
