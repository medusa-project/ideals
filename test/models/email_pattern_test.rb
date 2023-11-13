require "test_helper"

class EmailPatternTest < ActiveSupport::TestCase

  # matches?()

  test "matches?() returns false for a non-matching literal substring" do
    pattern = email_patterns(:literal)
    assert !pattern.matches?("user@bogus.net")
  end

  test "matches?() returns true for a matching literal substring" do
    pattern = email_patterns(:literal)
    assert pattern.matches?("user@example.org")
  end

  test "matches?() returns false for a non-matching regexp" do
    pattern = email_patterns(:regexp)
    assert !pattern.matches?("user@bogus.net")
  end

  test "matches?() returns true for a matching regexp" do
    pattern = email_patterns(:regexp)
    assert pattern.matches?("user@example.org")
  end

  # pattern

  test "pattern is required" do
    assert_raises ActiveRecord::RecordInvalid do
      EmailPattern.create!(pattern: "")
    end
  end

  test "pattern is normalized" do
    pattern = email_patterns(:literal)
    pattern.pattern = " test  test "
    assert_equal "test  test", pattern.pattern
  end

  # to_s()

  test "to_s() returns a correct value" do
    pattern = email_patterns(:regexp)
    assert_equal pattern.pattern, pattern.to_s
  end

end
