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

  # add_default_elements()

  test "add_default_elements() adds default elements to an instance that does
  not have any elements" do
    profile = MetadataProfile.create!(name:        "Test Profile",
                                      institution: institutions(:uiuc))
    profile.add_default_elements
    assert profile.elements.count > 1
  end

  test "add_default_elements() raises an error if the instance already has
  elements attached to it" do
    profile = metadata_profiles(:default)
    assert_raises do
      profile.add_default_elements
    end
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

  # faceted_elements()

  test "faceted_elements() returns only faceted elements" do
    assert_equal ["Subject"], @instance.faceted_elements.map(&:label)
  end

  # full_text_relevance_weight

  test "full_text_relevance_weight must be greater than 0" do
    assert @instance.valid?
    @instance.full_text_relevance_weight = 0
    assert !@instance.valid?
  end

  test "full_text_relevance_weight must be less than 11" do
    assert @instance.valid?
    @instance.full_text_relevance_weight = 11
    assert !@instance.valid?
  end

  test "full_text_relevance_weight can be between 1 and 10" do
    assert @instance.valid?
    @instance.full_text_relevance_weight = 5
    assert @instance.valid?
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
