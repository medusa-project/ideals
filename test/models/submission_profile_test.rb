require 'test_helper'

class SubmissionProfileTest < ActiveSupport::TestCase

  setup do
    @instance = submission_profiles(:uiuc_default)
  end

  # base-level tests

  test "destroying an instance destroys its dependent SubmissionProfileElements" do
    elements = @instance.elements
    @instance.collections = []
    @instance.destroy!
    elements.each do |element|
      assert element.destroyed?
    end
  end

  # add_required_elements()

  test "add_required_elements() adds required elements to an instance" do
    profile = SubmissionProfile.create!(name:        "Test Profile",
                                        institution: institutions(:uiuc))
    profile.add_required_elements
    assert_equal profile.institution.required_elements.length,
                 profile.elements.count
  end

  test "add_required_elements() adds only elements of the same institution as
  the instance" do
    profile = SubmissionProfile.create!(name:        "Test Profile",
                                        institution: institutions(:uiuc))
    profile.add_required_elements
    profile.elements.each do |e|
      assert_equal e.registered_element.institution, profile.institution
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
