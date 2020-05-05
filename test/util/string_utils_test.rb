require 'test_helper'

class StringUtilsTest < ActiveSupport::TestCase

  # uofi_email?()

  test "uofi_email?() returns true for UofI email addresses" do
    assert StringUtils.uofi_email?("test@illinois.edu")
    assert StringUtils.uofi_email?("test@uillinois.edu")
    assert StringUtils.uofi_email?("test@uiuc.edu")
    assert StringUtils.uofi_email?("TEST@UIUC.EDU")
  end

  test "uofi_email?() returns false for non-UofI email addresses" do
    assert !StringUtils.uofi_email?("test@example.org")
    assert !StringUtils.uofi_email?("test@not-illinois.edu")
  end

  test "uofi_email?() returns false for malformed email addresses" do
    assert !StringUtils.uofi_email?("not an email address")
  end

  # valid_email?()

  test "valid_email?() returns true for a valid email" do
    assert StringUtils.valid_email?("john-doe@example.org")
  end

  test "valid_email?() returns false for an invalid email" do
    assert !StringUtils.valid_email?("example.org")
    assert !StringUtils.valid_email?("user at example.org")
  end

end
