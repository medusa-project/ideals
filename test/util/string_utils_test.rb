require 'test_helper'

class StringUtilsTest < ActiveSupport::TestCase

  # rot18()

  test 'rot18 works' do
    str = 'set:8132f520-e3fb-012f-c5b6-0019b9e633c5-f|start:100|metadataPrefix:oai_dc'
    expected = 'frg:3687s075-r8so-567s-p0o1-5564o4r188p0-s|fgneg:655|zrgnqngnCersvk:bnv_qp'
    assert_equal expected, StringUtils.rot18(str)
  end

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

  # url_encode()

  test "url_encode() returns a URL-encoded string" do
    assert_equal "word%20word", StringUtils.url_encode("word word")
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
