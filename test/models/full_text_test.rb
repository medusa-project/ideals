require 'test_helper'

class FullTextTest < ActiveSupport::TestCase

  # bitstream

  test "bitstream is required" do
    text = FullText.new(text: "cats")
    assert !text.valid?
  end

  # text

  test "text cannot be blank" do
    text = FullText.new(bitstream: bitstreams(:southeast_approved_in_permanent),
                        text:      nil)
    assert !text.valid?
  end

  # to_s()

  test "to_s() returns the text" do
    text = FullText.new(bitstream: bitstreams(:southeast_approved_in_permanent),
                        text:      "cats")
    assert_equal "cats", text.text
  end

end
