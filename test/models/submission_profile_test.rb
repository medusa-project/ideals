require 'test_helper'

class SubmissionProfileTest < ActiveSupport::TestCase

  setup do
    @instance = submission_profiles(:uiuc_default)
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

  # add_default_elements()

  test "add_default_elements() adds default elements to an instance that does
  not have any elements" do
    profile = SubmissionProfile.create!(name:        "Test Profile",
                                        institution: institutions(:uiuc))
    profile.add_default_elements
    assert profile.elements.count > 1
  end

  test "add_default_elements() adds only elements of the same institution as
  the instance" do
    profile = SubmissionProfile.create!(name:        "Test Profile",
                                        institution: institutions(:uiuc))
    profile.add_default_elements
    profile.elements.each do |e|
      assert_equal e.registered_element.institution, profile.institution
    end
  end

  test "add_default_elements() raises an error if the instance already has
  elements attached to it" do
    profile = submission_profiles(:uiuc_default)
    assert_raises do
      profile.add_default_elements
    end
  end

  # default

  test "setting a profile as the default sets all other instances to not-default" do
    institution = institutions(:uiuc)
    assert_equal 1, institution.submission_profiles.where(institution_default: true).count
    SubmissionProfile.create!(name:                "New Profile",
                              institution:         institution,
                              institution_default: true)
    assert_equal 1, institution.submission_profiles.where(institution_default: true).count
  end

  # dup()

  test "dup() returns a correct clone of an instance" do
    dup = @instance.dup
    assert_equal "Clone of #{@instance.name}", dup.name
    assert !dup.institution_default
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
