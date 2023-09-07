require 'test_helper'

class FileFormatTest < ActiveSupport::TestCase

  test "for_extension() returns a format for the given extension" do
    format = FileFormat.for_extension("jpg")
    assert_equal "image", format.category
    assert_equal "imagemagick", format.derivative_generator
    assert_equal %w(jpg jpeg), format.extensions
    assert_equal "file-image-o", format.icon
    assert_equal "JPEG JFIF", format.long_name
    assert_equal %w(image/jpeg), format.media_types
    assert_equal "JPEG", format.short_name
    assert_equal "image_tag_for", format.viewer_method
  end

  test "for_extension() returns nil for an unrecognized extension" do
    assert_nil FileFormat.for_extension("bogus")
  end

end
