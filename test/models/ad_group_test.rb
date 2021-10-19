require 'test_helper'

class AdGroupTest < ActiveSupport::TestCase

  setup do
    @instance = ad_groups(:sysadmin)
  end

  # short_name()

  test "short_name() returns a correct value" do
    @instance.urn = "urn:system admin"
    assert_equal "System Admin", @instance.short_name
  end

  # to_s()

  test "to_s() returns a correct value" do
    assert_equal @instance.urn, @instance.to_s
  end

  # urn

  test "urn cannot be blank" do
    assert_raises ActiveRecord::RecordInvalid do
      AdGroup.create!(urn: "")
    end
  end

  test "urn must be unique" do
    assert_raises ActiveRecord::RecordNotUnique do
      AdGroup.create!(urn: @instance.urn)
    end
  end

end
