require 'test_helper'

class AscribedElementTest < ActiveSupport::TestCase

  setup do
    @instance = ascribed_elements(:item_title)
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

  test "instance's owning collection is updated when the instance is updated" do
    collection = collections(:described)
    original_updated_at = collection.updated_at

    sleep 0.1
    element = collection.elements.first
    element.update!(string: "new string")
    collection.reload
    new_updated_at = collection.updated_at

    assert new_updated_at > original_updated_at
  end

  test "instance's owning item is updated when the instance is updated" do
    item = items(:described)
    original_updated_at = item.updated_at

    sleep 0.1
    element = item.elements.first
    element.update!(string: "new string")
    item.reload
    new_updated_at = item.updated_at

    assert new_updated_at > original_updated_at
  end

  # label()

  test "label() returns the associated RegisteredElement label" do
    assert_equal "Title", @instance.label
  end

  test "label() returns nil when there is no associated RegisteredElement" do
    @instance.registered_element = nil
    assert_nil @instance.label
  end

  # name()

  test "name() returns the associated RegisteredElement name" do
    assert_equal "dc:title", @instance.name
  end

  test "name() returns nil when there is no associated RegisteredElement" do
    @instance.registered_element = nil
    assert_nil @instance.name
  end

end
