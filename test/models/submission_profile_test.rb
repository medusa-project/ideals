require 'test_helper'

class SubmissionProfileTest < ActiveSupport::TestCase

  setup do
    @instance = submission_profiles(:default)
  end

  # base-level tests

  test "instances with dependent collections cannot be destroyed" do
    assert_raises ActiveRecord::DeleteRestrictionError do
      @instance.destroy!
    end
  end

  test "destroying an instance destroys its dependent SubmissionProfileElements" do
    elements = @instance.elements
    @instance.collections = []
    @instance.destroy!
    elements.each do |element|
      assert element.destroyed?
    end
  end

  # default()

  test "default() returns the default submission profile" do
    assert_equal submission_profiles(:default).id, SubmissionProfile.default.id
  end

  # default

  test "setting a profile as the default sets all other instances to not-default" do
    assert_equal 1, SubmissionProfile.where(default: true).count
    SubmissionProfile.create!(name:        "New Profile",
                              institution: institutions(:uiuc),
                              default:     true)
    assert_equal 1, SubmissionProfile.where(default: true).count
  end

  # dup()

  test "dup() returns a correct clone of an instance" do
    dup = @instance.dup
    assert_equal "Clone of #{@instance.name}", dup.name
    assert !dup.default
    assert_equal @instance.elements.length, dup.elements.length
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
    profile = SubmissionProfile.all.first
    assert_raises ActiveRecord::RecordInvalid do
      SubmissionProfile.create!(name: profile.name)
    end
  end

end
