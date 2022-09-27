require 'test_helper'

class RegisteredElementTest < ActiveSupport::TestCase

  setup do
    @instance = registered_elements(:uiuc_dc_title)
    assert @instance.valid?
  end

  # base-level tests

  test "instances with attached AscribedElements cannot be destroyed" do
    assert_raises ActiveRecord::InvalidForeignKey do
      @instance.destroy!
    end
  end

  test "instances without attached AscribedElements can be destroyed" do
    assert registered_elements(:uiuc_unused).destroy
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

  # indexed_keyword_field()

  test "indexed_keyword_field() returns the expected name" do
    assert_equal "t_element_dc_title.keyword", @instance.indexed_keyword_field
  end

  test "indexed_keyword_field() replaces reserved characters" do
    assert_equal "t_element_dc_title.keyword", @instance.indexed_keyword_field
  end

  # indexed_field()

  test "indexed_field() returns the expected name of a text-type field" do
    assert_equal "t_element_dc_title", @instance.indexed_field
  end

  test "indexed_field() returns the expected name of a date-type field" do
    @instance.input_type = RegisteredElement::InputType::DATE
    assert_equal "d_element_dc_title", @instance.indexed_field
  end

  test "indexed_field() replaces reserved characters" do
    assert_equal "t_element_dc_title", @instance.indexed_field
  end

  # indexed_sort_field()

  test "indexed_sort_field() returns the expected name of a non-date-type field" do
    assert_equal "t_element_dc_title.sort", @instance.indexed_sort_field
  end

  test "indexed_sort_field() returns the expected name of a date-type field" do
    @instance.input_type = RegisteredElement::InputType::DATE
    assert_equal "d_element_dc_title", @instance.indexed_sort_field
  end

  test "indexed_sort_field() replaces reserved characters" do
    assert_equal "t_element_dc_title.sort", @instance.indexed_sort_field
  end

  # indexed_text_field()

  test "indexed_text_field() returns the expected name" do
    assert_equal "t_element_dc_title", @instance.indexed_text_field
  end

  test "indexed_text_field() replaces reserved characters" do
    assert_equal "t_element_dc_title", @instance.indexed_text_field
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

  # name

  test "name must be present" do
    @instance.name = nil
    assert !@instance.valid?
    @instance.name = ""
    assert !@instance.valid?
  end

  test "name must be unique" do
    element = RegisteredElement.all.first
    assert_raises ActiveRecord::RecordInvalid do
      RegisteredElement.create!(name: element.name,
                                label: "new label")
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

  # uri

  test "uri must be unique" do
    element = RegisteredElement.all.first
    assert_raises ActiveRecord::RecordInvalid do
      RegisteredElement.create!(label: "new label",
                                name: "new name",
                                uri: element.uri)
    end
  end

  # vocabulary()

  test "vocabulary() returns nil when vocabulary_key is nil" do
    @instance.vocabulary_key = nil
    assert_nil @instance.vocabulary
  end

  test "vocabulary() returns the Vocabulary corresponding to vocabulary_key" do
    @instance.vocabulary_key = :common_types
    assert_equal Vocabulary.with_key(@instance.vocabulary_key),
                 @instance.vocabulary
  end

end
