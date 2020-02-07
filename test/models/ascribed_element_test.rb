require 'test_helper'

class AscribedElementTest < ActiveSupport::TestCase

  setup do
    @instance = ascribed_elements(:item1_title)
    assert @instance.valid?
  end

  # base-level tests

  test "instances must be attached to a resource" do
    assert_raises ActiveRecord::RecordInvalid do
      AscribedElement.create!(registered_element: registered_elements(:title),
                              string: "Whatever")
    end
  end

  test "instances cannot be attached to multiple resources" do
    assert_raises ActiveRecord::RecordInvalid do
      AscribedElement.create!(registered_element: registered_elements(:title),
                              collection: collections(:collection1),
                              item: items(:item1),
                              string: "Whatever")
    end
  end

  # name()

  test "name() returns the associated RegisteredElement name" do
    assert_equal "title", @instance.name
  end

end
