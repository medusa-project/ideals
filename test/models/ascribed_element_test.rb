require 'test_helper'

class AscribedElementTest < ActiveSupport::TestCase

  setup do
    @instance = ascribed_elements(:described_title)
    assert @instance.valid?
  end

  # base-level tests

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

  # date()

  test "date() returns a valid instance when the string contains a recognized date" do
    @instance.string = "February 7, 1968"
    assert_equal Date.parse("February 7, 1968"), @instance.date
  end

  test "date() returns nil when the string does not contain a recognized date" do
    @instance.string = "the quick brown fox"
    assert_nil @instance.date
  end

  test "date() returns nil when the string is nil" do
    @instance.string = nil
    assert_nil @instance.date
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

  # person_name()

  test "person_name() returns a correct name" do
    @instance.string = "Flintstone, Fred"
    assert_equal({ family_name: "Flintstone", given_name: "Fred" },
                 @instance.person_name)

    @instance.string = "Flintstone, Fred, Esq."
    assert_equal({ family_name: "Flintstone", given_name: "Fred, Esq." },
                 @instance.person_name)
  end

  test "person_name() returns nil when the instance does not appear to contain
  a name" do
    assert_nil @instance.person_name
  end

end
