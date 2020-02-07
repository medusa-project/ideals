require 'test_helper'

class RegisteredElementTest < ActiveSupport::TestCase

  setup do
    @instance = registered_elements(:title)
    assert @instance.valid?
  end

  # base-level tests

  test "instances with attached AscribedElements cannot be destroyed" do
    assert_raises ActiveRecord::InvalidForeignKey do
      @instance.destroy!
    end
  end

  test "instances without attached AscribedElements can be destroyed" do
    assert registered_elements(:unused).destroy
  end

  # sortable_field()

  test "sortable_field() returns the expected name" do
    assert_equal "metadata_title.sort",
                 RegisteredElement.sortable_field("title")
  end

  # indexed_name()

  test "indexed_name() returns the expected name" do
    assert_equal "metadata_dc:title", @instance.indexed_name
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
      RegisteredElement.create!(name: element.name)
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

end
