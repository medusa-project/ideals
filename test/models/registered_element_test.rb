require 'test_helper'

class RegisteredElementTest < ActiveSupport::TestCase

  setup do
    @instance = registered_elements(:title)
    assert @instance.valid?
  end

  test "name must be present" do
    @instance.name = nil
    assert !@instance.valid?
    @instance.name = ""
    assert !@instance.valid?
  end

  test "name must be unique" do
    assert_raises ActiveRecord::RecordInvalid do
      RegisteredElement.create!(name: "title")
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
