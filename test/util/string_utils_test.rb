require 'test_helper'

class StringUtilsTest < ActiveSupport::TestCase

  # valid_email?()

  test "valid_email?() returns true for a valid email" do
    assert StringUtils.valid_email?("john-doe@example.org")
  end

  test "valid_email?() returns false for an invalid email" do
    assert !StringUtils.valid_email?("example.org")
    assert !StringUtils.valid_email?("user at example.org")
  end

end
