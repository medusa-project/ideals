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
    @instance.update!(visible: false)
    time2 = profile.updated_at
    assert time2 > time1
  end

  # create()

  test "create() updates positions in the owning profile" do
    reg_element = RegisteredElement.create!(institution: institutions(:uiuc),
                                            name:        "newElement",
                                            label:       "New Element")
    profile = metadata_profiles(:default)
    MetadataProfileElement.create!(position: 1,
                                   registered_element: reg_element,
                                   metadata_profile: profile)
    # Assert that the positions are sequential and zero-based.
    profile.elements.order(:position).each_with_index do |e, i|
      assert_equal i, e.position
    end
  end

  # destroy()

  test "destroy() updates positions in the owning profile" do
    profile = @instance.metadata_profile
    @instance.destroy!
    # Assert that the positions are sequential and zero-based.
    profile.elements.order(:position).each_with_index do |e, i|
      assert_equal i, e.position
    end
  end

  # indexed_field()

  test "indexed_field() returns the expected name" do
    assert_equal "metadata_dc_title",
                 @instance.registered_element.indexed_field
  end

  test "indexed_field() replaces reserved characters" do
    assert_equal "metadata_dc_title",
                 @instance.registered_element.indexed_field
  end

  # indexed_keyword_field()

  test "indexed_keyword_field() returns the expected name" do
    assert_equal "metadata_dc_title.keyword",
                 @instance.registered_element.indexed_keyword_field
  end

  test "indexed_keyword_field() replaces reserved characters" do
    assert_equal "metadata_dc_title.keyword",
                 @instance.registered_element.indexed_keyword_field
  end

  # indexed_sort_field()

  test "indexed_sort_field() returns the expected name" do
    assert_equal "metadata_dc_title.sort",
                 @instance.registered_element.indexed_sort_field
  end

  test "indexed_sort_field() replaces reserved characters" do
    assert_equal "metadata_dc_title.sort",
                 @instance.registered_element.indexed_sort_field
  end

  # label()

  test "label() returns the label of the associated RegisteredElement" do
    assert_equal "Title", @instance.label
  end

  # metadata_profile

  test "metadata_profile is required" do
    assert_raises ActiveRecord::RecordInvalid do
      MetadataProfileElement.create!(position: 0,
                                     registered_element: registered_elements(:dc_title))
    end
  end

  # name()

  test "name() returns the name of the associated RegisteredElement" do
    assert_equal "dc:title", @instance.name
  end

  # position

  test "position is required" do
    assert_raises ActiveRecord::RecordInvalid do
      MetadataProfileElement.create!(metadata_profile: metadata_profiles(:default),
                                     registered_element: registered_elements(:dc_title))
    end
  end

  test 'position must be greater than or equal to 0' do
    @instance.position = -1
    assert !@instance.valid?
  end

  # registered_element

  test "registered_element is required" do
    assert_raises ActiveRecord::RecordInvalid do
      MetadataProfileElement.create!(position: 0,
                                     metadata_profile: metadata_profiles(:default))
    end
  end

  test "registered_element must be unique within a metadata profile" do
    profile = metadata_profiles(:unused)
    profile.elements.build(position: 0,
                           registered_element: registered_elements(:dc_title))
    profile.elements.build(position: 1,
                           registered_element: registered_elements(:dc_title))
  end

  # update()

  test "update() update positions in the owning profile when increasing an
  element position" do
    assert_equal 0, @instance.position
    @instance.update!(position: 2)
    # Assert that the positions are sequential and zero-based.
    @instance.metadata_profile.elements.order(:position).each_with_index do |e, i|
      assert_equal i, e.position
    end
  end

  test "update() updates positions in the owning profile when decreasing an
  element position" do
    @instance = @instance.metadata_profile.elements.where(position: 2).first
    @instance.update!(position: 0)
    # Assert that the positions are sequential and zero-based.
    @instance.metadata_profile.elements.order(:position).each_with_index do |e, i|
      assert_equal i, e.position
    end
  end

end
