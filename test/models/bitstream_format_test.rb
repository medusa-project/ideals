require 'test_helper'

class BitstreamFormatTest < ActiveSupport::TestCase

  setup do
    @instance = bitstream_formats(:jpeg)
    assert @instance.valid?
  end

  # destroy()

  test "bitstream formats with dependent bitstreams cannot be destroyed" do
    assert_raises ActiveRecord::InvalidForeignKey do
      @instance.destroy!
    end
  end

  # description

  test "description must be present" do
    @instance.description = nil
    assert !@instance.valid?
    @instance.description = ""
    assert !@instance.valid?
  end

  # media_type

  test "media_type must be present" do
    @instance.media_type = nil
    assert !@instance.valid?
    @instance.media_type = ""
    assert !@instance.valid?
  end

  test "media_type must have a correct format" do
    @instance.media_type = "bogus"
    assert !@instance.valid?
    @instance.media_type = "bogus bogus"
    assert !@instance.valid?
    @instance.media_type = "application/xhtml+xml"
    assert @instance.valid?
  end

  # short_description

  test "short_description must be present" do
    @instance.short_description = nil
    assert !@instance.valid?
    @instance.short_description = ""
    assert !@instance.valid?
  end

end
