require 'test_helper'

class AdGroupTest < ActiveSupport::TestCase

  setup do
    @instance = ad_groups(:sysadmin)
  end

  # name

  test "name cannot be blank" do
    assert_raises ActiveRecord::RecordInvalid do
      AdGroup.create!(name: "")
    end
  end

  test "name is normalized" do
    @instance.name = " test  test "
    assert_equal "test test", @instance.name
  end

  # to_s()

  test "to_s() returns a correct value" do
    assert_equal @instance.name, @instance.to_s
  end

end
