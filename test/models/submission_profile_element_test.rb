require 'test_helper'

class SubmissionProfileElementTest < ActiveSupport::TestCase

  setup do
    @instance = submission_profile_elements(:uiuc_default_title)
    assert @instance.valid?
  end

  # base-level tests

  test "updating an instance updates its associated SubmissionProfile" do
    profile = @instance.submission_profile
    time1 = profile.updated_at
    @instance.update!(repeatable: !@instance.repeatable)
    time2 = profile.updated_at
    assert time2 > time1
  end

  # create()

  test "create() updates indexes in the owning profile" do
    reg_element = RegisteredElement.create!(institution: institutions(:uiuc),
                                            name:        "newElement",
                                            label:       "New Element")
    profile = submission_profiles(:uiuc_default)
    SubmissionProfileElement.create!(position: 1,
                                     registered_element: reg_element,
                                     submission_profile: profile)
    # Assert that the indexes are sequential and zero-based.
    profile.elements.order(:position).each_with_index do |e, i|
      assert_equal i, e.position
    end
  end

  # destroy()

  test "destroy() updates indexes in the owning profile" do
    profile = @instance.submission_profile
    @instance.destroy!
    # Assert that the indexes are sequential and zero-based.
    profile.elements.order(:position).each_with_index do |e, i|
      assert_equal i, e.position
    end
  end

  # label()

  test "label() returns the label of the associated RegisteredElement" do
    assert_equal @instance.registered_element.label, @instance.label
  end

  # name()

  test "name() returns the label of the associated RegisteredElement" do
    assert_equal @instance.registered_element.name, @instance.name
  end

  # position

  test "position is required" do
    assert_raises ActiveRecord::RecordInvalid do
      SubmissionProfileElement.create!(submission_profile: submission_profiles(:uiuc_default),
                                       registered_element: registered_elements(:uiuc_dc_title))
    end
  end

  test 'position must be greater than or equal to 0' do
    @instance.position = -1
    assert !@instance.valid?
  end

  # submission_profile

  test "submission_profile is required" do
    assert_raises ActiveRecord::RecordInvalid do
      SubmissionProfileElement.create!(position: 0,
                                       registered_element: registered_elements(:uiuc_dc_title))
    end
  end

  # registered_element

  test "registered_element is required" do
    assert_raises ActiveRecord::RecordInvalid do
      SubmissionProfileElement.create!(position: 0,
                                       submission_profile: submission_profiles(:uiuc_default))
    end
  end

  test "registered_element must be unique within a submission profile" do
    profile = submission_profiles(:uiuc_unused)
    profile.elements.build(position: 0,
                           registered_element: registered_elements(:uiuc_dc_title))
    profile.elements.build(position: 1,
                           registered_element: registered_elements(:uiuc_dc_title))
  end

  test "registered_element must be of the same institution as the owning profile" do
    @instance.registered_element = registered_elements(:northeast_dc_title)
    assert !@instance.valid?
  end

  # update()

  test "update() update indexes in the owning profile when increasing an element index" do
    assert_equal 0, @instance.position
    @instance.update!(position: 2)
    # Assert that the indexes are sequential and zero-based.
    @instance.submission_profile.elements.order(:position).each_with_index do |e, i|
      assert_equal i, e.position
    end
  end

  test "update() updates indexes in the owning profile when decreasing an element index" do
    @instance = @instance.submission_profile.elements.where(position: 2).first
    @instance.update!(position: 0)
    # Assert that the indexes are sequential and zero-based.
    @instance.submission_profile.elements.order(:position).each_with_index do |e, i|
      assert_equal i, e.position
    end
  end

end
