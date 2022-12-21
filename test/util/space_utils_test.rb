require 'test_helper'

class SpaceUtilsTest < ActiveSupport::TestCase

  test "dms_to_decimal() with nil arguments returns zero" do
    result = SpaceUtils.dms_to_decimal(nil, nil, nil)
    assert_equal 0.0, result
  end

  test "dms_to_decimal() returns a correct value" do
    result = SpaceUtils.dms_to_decimal(40, 6, 35)
    assert result > 40.1097
    assert result < 40.1098
    result = SpaceUtils.dms_to_decimal(-88, 12, 15)
    assert result > -88.2042
    assert result < -88.2041
  end

end
