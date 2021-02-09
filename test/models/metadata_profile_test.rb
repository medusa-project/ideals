require 'test_helper'

class MetadataProfileTest < ActiveSupport::TestCase

  setup do
    @instance = metadata_profiles(:default)
  end

  # base-level tests

  test "instances with dependent collections cannot be destroyed" do
    assert_raises ActiveRecord::DeleteRestrictionError do
      @instance.destroy!
    end
  end

  test "destroying an instance destroys its dependent MetadataProfileElements" do
    elements = @instance.elements
    @instance.collections = []
    @instance.destroy!
    elements.each do |element|
      assert element.destroyed?
    end
  end

  # default()

  test "default() returns the default metadata profile" do
    assert_equal metadata_profiles(:default).id, MetadataProfile.default.id
  end

  # default

  test "setting a profile as the default sets all other instances to not-default" do
    assert_equal 1, MetadataProfile.where(default: true).count
    MetadataProfile.create!(name:        "New Profile",
                            institution: institutions(:uiuc),
                            default:     true)
    assert_equal 1, MetadataProfile.where(default: true).count
  end

  # dup()

  test "dup() returns a correct clone of an instance" do
    dup = @instance.dup
    assert_equal "Clone of #{@instance.name}", dup.name
    assert !dup.default
    assert_equal @instance.elements.length, dup.elements.length
  end

  # facetable_elements()

  test "facetable_elements() returns only facetable elements" do
    assert_equal ["Subject"], @instance.facetable_elements.map(&:label)
  end

  # name

  test "name must be present" do
    @instance.name = nil
    assert !@instance.valid?
    @instance.name = ""
    assert !@instance.valid?
  end

  test "name must be at least 2 characters long" do
    @instance.name = "a"
    assert !@instance.valid?
    @instance.name = "aa"
    assert @instance.valid?
  end

  test "name must be unique" do
    profile = MetadataProfile.all.first
    assert_raises ActiveRecord::RecordInvalid do
      MetadataProfile.create!(name: profile.name)
    end
  end

end
