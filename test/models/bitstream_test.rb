require 'test_helper'

class BitstreamTest < ActiveSupport::TestCase

  setup do
    @instance = bitstreams(:item1_jpg)
    assert @instance.valid?
  end

  test "key must be present" do
    @instance.key = nil
    assert !@instance.valid?
    @instance.key = ""
    assert !@instance.valid?
  end

  test "key must be unique" do
    @instance.update!(key:"cats")
    assert_raises ActiveRecord::RecordInvalid do
      Bitstream.create!(key: "cats", item: items(:item1))
    end
  end

  test "length must be greater than or equal to zero" do
    @instance.length = -1
    assert !@instance.valid?
    @instance.length = 0
    assert @instance.valid?
    @instance.length = 1
    assert @instance.valid?
  end

  test "media_type must be a correct format" do
    @instance.media_type = 'bogus'
    assert !@instance.valid?
  end

end
