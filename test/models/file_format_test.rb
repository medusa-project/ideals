require 'test_helper'

class FileFormatTest < ActiveSupport::TestCase

  setup do
    @format = FileFormat.for_extension("jpg")
  end

  # for_extension()

  test "for_extension() returns a format for the given extension" do
    assert_equal "image", @format.category
    assert_equal "imagemagick", @format.derivative_generator
    assert_equal %w(jpg jpeg), @format.extensions
    assert_equal "file-image-o", @format.icon
    assert_equal "JPEG JFIF", @format.long_name
    assert_equal %w(image/jpeg), @format.media_types
    assert_equal "JPEG", @format.short_name
    assert_equal "image_tag_for", @format.viewer_method
  end

  test "for_extension() returns nil for an unrecognized extension" do
    assert_nil FileFormat.for_extension("bogus")
  end

  # ==()

  test "==() returns true for equal objects" do
    assert_equal FileFormat.for_extension("gz"), FileFormat.for_extension("tgz")
  end

  test "==() returns false for unequal objects" do
    assert_not_equal FileFormat.for_extension("jpg"),
                     FileFormat.for_extension("tgz")
  end

  # media_type()

  test "media_type() returns the first media type" do
    assert_equal "image/jpeg", @format.media_type
  end

end
