require 'test_helper'

class DepartmentTest < ActiveSupport::TestCase

  setup do
    @instance = departments(:basket_weaving)
  end

  # name

  test "name is normalized" do
    @instance.name = " test  test "
    assert_equal "test test", @instance.name
  end

end
