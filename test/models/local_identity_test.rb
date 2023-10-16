require 'test_helper'

class LocalIdentityTest < ActiveSupport::TestCase

  include ActionMailer::TestHelper

  setup do
    @instance = local_identities(:southwest)
  end

  # create()

  test "create() does not allow association with an expired Invitee" do
    assert_raises ActiveRecord::RecordInvalid do
      # LocalIdentity.create() is invoked indirectly
      Invitee.create!(email:      "test@example.org",
                      expires_at: 10.years.ago)
    end
  end

  # new_token()

  test "new_token() returns a token" do
    assert_not_empty LocalIdentity.new_token
  end

  # random_password()

  test "random_password() returns a valid random password" do
    password = LocalIdentity.random_password
    assert password.length >= LocalIdentity::PASSWORD_MIN_LENGTH
    assert password.gsub(/[^a-z]/, "").length >= LocalIdentity::PASSWORD_MIN_LOWERCASE_LETTERS
    assert password.gsub(/[^A-Z]/, "").length >= LocalIdentity::PASSWORD_MIN_UPPERCASE_LETTERS
    assert password.gsub(/[^0-9]/, "").length >= LocalIdentity::PASSWORD_MIN_NUMBERS
    assert password.gsub(/[^#{LocalIdentity::PASSWORD_SPECIAL_CHARACTERS}]/, "").length >= LocalIdentity::PASSWORD_MIN_SPECIAL_CHARACTERS
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

  # invitee()

  test "invitee is required" do
    email    = "test@example.org"
    password = "password"
    assert_raises ActiveRecord::RecordInvalid do
      @instance = LocalIdentity.create!(email:                 email,
                                        password:              password,
                                        password_confirmation: password)
    end
  end

  # lowercase_email

  test "lowercase_email is set upon save" do
    email = "MixedCase@Example.Org"
    @instance.update!(email: email)
    assert_equal email.downcase, @instance.lowercase_email
  end

  # password_reset_url()

  test "password_reset_url raises an error if reset_token is blank" do
    assert_raises RuntimeError do
      @instance.password_reset_url
    end
  end

  test "password_reset_url() returns a correct URL" do
    @instance.create_reset_digest
    expected = sprintf("http://%s/identities/%d/reset-password?token=%s",
                       @instance.user.institution.fqdn,
                       @instance.id,
                       @instance.reset_token)
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
    expected = sprintf("http://%s/identities/%d/register?token=%s",
                       @instance.user.institution.fqdn,
                       @instance.id,
                       @instance.registration_token)
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

  # update_password!()

  test "update_password!() raises an error for a password that is too short" do
    assert_raises ActiveRecord::RecordInvalid do
      @instance.update_password!(password:     "short",
                                 confirmation: "short")
    end
  end

  test "update_password!() raises an error for a password that does not contain
  at least one lowercase letter" do
    assert_raises ActiveRecord::RecordInvalid do
      @instance.update_password!(password:     "ALLCAPS123!",
                                 confirmation: "ALLCAPS123!")
    end
  end

  test "update_password!() raises an error for a password that does not contain
  at least one uppercase letter" do
    assert_raises ActiveRecord::RecordInvalid do
      @instance.update_password!(password:     "alllower123!",
                                 confirmation: "alllower123!")
    end
  end

  test "update_password!() raises an error for a password that does not contain
  at least one number" do
    assert_raises ActiveRecord::RecordInvalid do
      @instance.update_password!(password:     "MyPassword!",
                                 confirmation: "MyPassword!")
    end
  end

  test "update_password!() raises an error for a password that does not contain
  at least one special character" do
    assert_raises ActiveRecord::RecordInvalid do
      @instance.update_password!(password:     "MyPassword123",
                                 confirmation: "MyPassword123")
    end
  end

  test "update_password!() raises an error if the confirmation does not match
  the password" do
    assert_raises ActiveRecord::RecordInvalid do
      @instance.update_password!(password:     LocalIdentity.random_password,
                                 confirmation: LocalIdentity.random_password)
    end
  end

  test "update_password!() updates the password" do
    digest       = @instance.password_digest
    new_password = LocalIdentity.random_password
    @instance.update_password!(password:     new_password,
                               confirmation: new_password)
    assert_not_equal digest, @instance.password_digest
  end

  test "update_password!() clears reset information" do
    new_password = LocalIdentity.random_password
    @instance.update_password!(password:     new_password,
                               confirmation: new_password)
    assert_nil @instance.reset_digest
    assert_nil @instance.reset_sent_at
  end

end
