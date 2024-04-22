require 'test_helper'

class StringUtilsTest < ActiveSupport::TestCase

  # rot18()

  test 'rot18 works' do
    str = 'set:8132f520-e3fb-012f-c5b6-0019b9e633c5-f|start:100|metadataPrefix:oai_dc'
    expected = 'frg:3687s075-r8so-567s-p0o1-5564o4r188p0-s|fgneg:655|zrgnqngnCersvk:bnv_qp'
    assert_equal expected, StringUtils.rot18(str)
  end

  # sanitize_filename()

  test "sanitize_filename() sanitizes a filename" do
    assert_equal "cats_dogs.jpg", StringUtils.sanitize_filename("cats/dogs.jpg")
  end

  # url_encode()

  test "url_encode() returns a URL-encoded string" do
    assert_equal "word%20word", StringUtils.url_encode("word word")
  end

  # utf8()

  test "utf8() converts a non-UTF-8 string to UTF-8" do
    str = [0x5a, 0xfc, 0x72, 0x69, 0x63, 0x68].pack('c*')
    assert_equal "Z?rich", StringUtils.utf8(str)
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
