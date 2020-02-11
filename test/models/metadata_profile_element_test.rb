require 'test_helper'

class MetadataProfileElementTest < ActiveSupport::TestCase

  setup do
    @instance = metadata_profile_elements(:default_title)
    assert @instance.valid?
  end

  # base-level tests

  test "updating an instance updates its associated MetadataProfile" do
    profile = @instance.metadata_profile
    time1 = profile.updated_at
    @instance.update!(label: "New Label")
    time2 = profile.updated_at
    assert time2 > time1
  end

  # create()

  test "create() updates indexes in the owning profile" do
    reg_element = RegisteredElement.create!(name: "newElement")
    profile = metadata_profiles(:default)
    MetadataProfileElement.create!(index: 1,
                                   label: "New Element",
                                   registered_element: reg_element,
                                   metadata_profile: profile)
    # Assert that the indexes are sequential and zero-based.
    profile.elements.order(:index).each_with_index do |e, i|
      assert_equal i, e.index
    end
  end

  # destroy()

  test "destroy() updates indexes in the owning profile" do
    profile = @instance.metadata_profile
    @instance.destroy!
    # Assert that the indexes are sequential and zero-based.
    profile.elements.order(:index).each_with_index do |e, i|
      assert_equal i, e.index
    end
  end

  # index

  test "index is required" do
    assert_raises ActiveRecord::RecordInvalid do
      MetadataProfileElement.create!(label: "New Element",
                                     metadata_profile: metadata_profiles(:default),
                                     registered_element: registered_elements(:title))
    end
  end

  test 'index must be greater than or equal to 0' do
    @instance.index = -1
    assert !@instance.valid?
  end

  # label

  test "label must be unique within a metadata profile" do
    @instance.metadata_profile.elements.each_with_index do |e, i|
      e.label = "title"
      if i == 0
        e.save!
      else
        assert_raises ActiveRecord::RecordInvalid do
          e.save!
        end
      end
    end
  end

  test "label does not need to be unique across metadata profiles" do
    profile1 = MetadataProfile.create!(name: "Test 1")
    profile1.elements.build(label: "Title",
                            registered_element: registered_elements(:title))
    profile2 = MetadataProfile.create!(name: "Test 2")
    profile2.elements.build(label: "Title",
                            registered_element: registered_elements(:title))
  end

  # metadata_profile

  test "metadata_profile is required" do
    assert_raises ActiveRecord::RecordInvalid do
      MetadataProfileElement.create!(label: "New Element",
                                     index: 0,
                                     registered_element: registered_elements(:title))
    end
  end

  # name()

  test "name() returns the name of the associated RegisteredElement" do
    assert_equal "dc:title", @instance.name
  end

  # registered_element

  test "registered_element is required" do
    assert_raises ActiveRecord::RecordInvalid do
      MetadataProfileElement.create!(label: "New Element",
                                     index: 0,
                                     metadata_profile: metadata_profiles(:default))
    end
  end

  test "registered_element must be unique within a metadata profile" do
    profile = metadata_profiles(:unused)
    profile.elements.build(label: "New Title 1",
                           index: 0,
                           registered_element: registered_elements(:title))
    profile.elements.build(label: "New Title 2",
                           index: 1,
                           registered_element: registered_elements(:title))
  end

  # update()

  test "update() update indexes in the owning profile when increasing an element index" do
    assert_equal 0, @instance.index
    @instance.update!(index: 2)
    # Assert that the indexes are sequential and zero-based.
    @instance.metadata_profile.elements.order(:index).each_with_index do |e, i|
      assert_equal i, e.index
    end
  end

  test "update() updates indexes in the owning profile when decreasing an element index" do
    @instance = @instance.metadata_profile.elements.where(index: 2).first
    @instance.update!(index: 0)
    # Assert that the indexes are sequential and zero-based.
    @instance.metadata_profile.elements.order(:index).each_with_index do |e, i|
      assert_equal i, e.index
    end
  end

end
