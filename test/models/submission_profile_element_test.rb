require 'test_helper'

class SubmissionProfileElementTest < ActiveSupport::TestCase

  setup do
    @instance = submission_profile_elements(:default_title)
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
    reg_element = RegisteredElement.create!(name: "newElement",
                                            label: "New Element")
    profile = submission_profiles(:default)
    SubmissionProfileElement.create!(index: 1,
                                     registered_element: reg_element,
                                     submission_profile: profile)
    # Assert that the indexes are sequential and zero-based.
    profile.elements.order(:index).each_with_index do |e, i|
      assert_equal i, e.index
    end
  end

  # destroy()

  test "destroy() updates indexes in the owning profile" do
    profile = @instance.submission_profile
    @instance.destroy!
    # Assert that the indexes are sequential and zero-based.
    profile.elements.order(:index).each_with_index do |e, i|
      assert_equal i, e.index
    end
  end

  # effective_label()

  test "effective_label() returns the label if set" do
    @instance.label = "cats"
    assert_equal "cats", @instance.effective_label
  end

  test "effective_label() returns the label of the associated RegisteredElement if not set" do
    @instance.label = nil
    assert_equal @instance.registered_element.label, @instance.effective_label
  end

  # index

  test "index is required" do
    assert_raises ActiveRecord::RecordInvalid do
      SubmissionProfileElement.create!(submission_profile: submission_profiles(:default),
                                       registered_element: registered_elements(:title))
    end
  end

  test 'index must be greater than or equal to 0' do
    @instance.index = -1
    assert !@instance.valid?
  end

  # input_type

  test "input_type must be one of the InputType constant values" do
    assert_raises ActiveRecord::RecordInvalid do
      @instance.update!(input_type: "bogus")
    end
  end

  test "input_type is allowed to be blank" do
    @instance.update!(input_type: nil)
  end

  # submission_profile

  test "submission_profile is required" do
    assert_raises ActiveRecord::RecordInvalid do
      SubmissionProfileElement.create!(index: 0,
                                       registered_element: registered_elements(:title))
    end
  end

  # registered_element

  test "registered_element is required" do
    assert_raises ActiveRecord::RecordInvalid do
      SubmissionProfileElement.create!(index: 0,
                                       submission_profile: submission_profiles(:default))
    end
  end

  test "registered_element must be unique within a submission profile" do
    profile = submission_profiles(:unused)
    profile.elements.build(index: 0,
                           registered_element: registered_elements(:title))
    profile.elements.build(index: 1,
                           registered_element: registered_elements(:title))
  end

  # update()

  test "update() update indexes in the owning profile when increasing an element index" do
    assert_equal 0, @instance.index
    @instance.update!(index: 2)
    # Assert that the indexes are sequential and zero-based.
    @instance.submission_profile.elements.order(:index).each_with_index do |e, i|
      assert_equal i, e.index
    end
  end

  test "update() updates indexes in the owning profile when decreasing an element index" do
    @instance = @instance.submission_profile.elements.where(index: 2).first
    @instance.update!(index: 0)
    # Assert that the indexes are sequential and zero-based.
    @instance.submission_profile.elements.order(:index).each_with_index do |e, i|
      assert_equal i, e.index
    end
  end

end
