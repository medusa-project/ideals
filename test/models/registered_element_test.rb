require 'test_helper'

class RegisteredElementTest < ActiveSupport::TestCase

  setup do
    @instance = registered_elements(:southeast_dc_contributor)
    assert @instance.valid?
  end

  # sortable_field()

  test "sortable_field() returns the expected name" do
    assert_equal "t_element_title.sort",
                 RegisteredElement.sortable_field("title")
  end

  test "sortable_field() replaces reserved characters" do
    assert_equal "t_element_dc_title.sort",
                 RegisteredElement.sortable_field("dc:title")
  end

  # dublin_core_mapping

  test "dublin_core_mapping must be set to a valid DC element" do
    @instance.dublin_core_mapping = "title"
    assert @instance.valid?
    @instance.dublin_core_mapping = "bogus"
    assert !@instance.valid?
  end

  # destroy()

  test "instances with attached AscribedElements cannot be destroyed" do
    item = items(:southeast_approved)
    item.elements.build(registered_element: @instance,
                        string:             "new element").save!
    assert_raises ActiveRecord::InvalidForeignKey do
      @instance.destroy!
    end
  end

  test "instances without attached AscribedElements can be destroyed" do
    assert registered_elements(:southeast_unused).destroy
  end

  # indexed_keyword_field()

  test "indexed_keyword_field() returns the expected name" do
    assert_equal "t_element_dc_contributor.keyword", @instance.indexed_keyword_field
  end

  test "indexed_keyword_field() replaces reserved characters" do
    assert_equal "t_element_dc_contributor.keyword", @instance.indexed_keyword_field
  end

  # indexed_field()

  test "indexed_field() returns the expected name of a text-type field" do
    assert_equal "t_element_dc_contributor", @instance.indexed_field
  end

  test "indexed_field() returns the expected name of a date-type field" do
    @instance.input_type = RegisteredElement::InputType::DATE
    assert_equal "d_element_dc_contributor", @instance.indexed_field
  end

  test "indexed_field() replaces reserved characters" do
    assert_equal "t_element_dc_contributor", @instance.indexed_field
  end

  # indexed_sort_field()

  test "indexed_sort_field() returns the expected name of a non-date-type field" do
    assert_equal "t_element_dc_contributor.sort", @instance.indexed_sort_field
  end

  test "indexed_sort_field() returns the expected name of a date-type field" do
    @instance.input_type = RegisteredElement::InputType::DATE
    assert_equal "d_element_dc_contributor", @instance.indexed_sort_field
  end

  test "indexed_sort_field() replaces reserved characters" do
    assert_equal "t_element_dc_contributor.sort", @instance.indexed_sort_field
  end

  # indexed_text_field()

  test "indexed_text_field() returns the expected name" do
    assert_equal "t_element_dc_contributor", @instance.indexed_text_field
  end

  test "indexed_text_field() replaces reserved characters" do
    assert_equal "t_element_dc_contributor", @instance.indexed_text_field
  end

  # input_type

  test "input_type must be one of the InputType constant values" do
    assert_raises ActiveRecord::RecordInvalid do
      @instance.update!(input_type: "bogus")
    end
  end

  test "input_type is assigned a default value before save" do
    @instance.update!(input_type: nil)
    @instance.reload
    assert_equal RegisteredElement::InputType::TEXT_FIELD, @instance.input_type
  end

  # institution

  test "institution cannot be set on template elements" do
    @instance.institution = institutions(:southeast)
    @instance.template    = true
    assert !@instance.valid?

    @instance.template = false
    assert @instance.valid?

    @instance.institution = nil
    @instance.template    = true
    assert @instance.valid?
  end

  # label

  test "label must be present" do
    @instance.label = nil
    assert !@instance.valid?
    @instance.label = ""
    assert !@instance.valid?
  end

  test "label must be unique" do
    element = RegisteredElement.all.first
    assert_raises ActiveRecord::RecordInvalid do
      RegisteredElement.create!(name: "new name",
                                label: element.label)
    end
  end

  test "label is normalized" do
    @instance.label = " test  test "
    assert_equal "test test", @instance.label
  end

  # migrate_ascribed_elements()

  test "migrate_ascribed_elements() raises an error when the given
  RegisteredElement resides in different institutions" do
    from_re = registered_elements(:southwest_dc_description)
    to_re   = registered_elements(:northeast_dc_description)
    assert_raises ArgumentError do
      from_re.migrate_ascribed_elements(to_registered_element: to_re)
    end
  end

  test "migrate_ascribed_elements() works properly" do
    from_re = registered_elements(:southeast_dc_subject)
    num_to_migrate = from_re.ascribed_elements.count
    assert num_to_migrate > 0
    to_re = registered_elements(:southeast_dc_description)
    to_re.ascribed_elements.destroy_all

    from_re.migrate_ascribed_elements(to_registered_element: to_re)

    from_re.reload
    to_re.reload
    assert_equal 0, from_re.ascribed_elements.count
    assert_equal num_to_migrate, to_re.ascribed_elements.count
  end

  # name

  test "name must be present" do
    @instance.name = nil
    assert !@instance.valid?
    @instance.name = ""
    assert !@instance.valid?
  end

  test "name must be unique within an institution" do
    element = RegisteredElement.all.first
    assert_raises ActiveRecord::RecordNotUnique do
      RegisteredElement.create!(name:        element.name,
                                institution: element.institution,
                                label:       "new label")
    end
  end

  test "name must be of an allowed format" do
    @instance.name = "catsCATS09:_-"
    assert @instance.valid?
    @instance.name = "@cats"
    assert !@instance.valid?
    @instance.name = "cats@"
    assert !@instance.valid?
    @instance.name = "c@ts"
    assert !@instance.valid?
  end

  test "name is normalized" do
    @instance.name = " test  test "
    assert_equal "test test", @instance.name
  end

  # uri

  test "uri must be unique" do
    element = RegisteredElement.all.first
    assert_raises ActiveRecord::RecordInvalid do
      RegisteredElement.create!(label: "new label",
                                name: "new name",
                                uri: element.uri)
    end
  end

  test "uri converts empty strings to nil" do
    @instance.uri = ""
    assert_nil @instance.uri
  end

  test "uri is normalized" do
    @instance.uri = " test  test "
    assert_equal "test test", @instance.uri
  end

end
