require 'test_helper'

class MetadataProfileTest < ActiveSupport::TestCase

  setup do
    @instance = metadata_profiles(:default)
  end

  # default

  test "setting a profile as the default sets all other instances to not-default" do
    assert_equal 1, MetadataProfile.where(default: true).count
    MetadataProfile.create!(name: "New Profile", default: true)
    assert_equal 1, MetadataProfile.where(default: true).count
  end

  # name

  test "name must be present" do
    @instance.name = nil
    assert !@instance.valid?
    @instance.name = ""
    assert !@instance.valid?
  end

  test "name must be unique" do
    profile = MetadataProfile.all.first
    assert_raises ActiveRecord::RecordNotUnique do
      MetadataProfile.create!(name: profile.name)
    end
  end

end
