require 'test_helper'

class AscribedElementTest < ActiveSupport::TestCase

  setup do
    @instance = ascribed_elements(:southeast_described_title)
    assert @instance.valid?
  end

  # base-level tests

  test "instance's associated RegisteredElement and Item must be associated
  with the same Institution" do
    @instance.registered_element = registered_elements(:southeast_dc_title)
    @instance.item               = items(:northeast_unit1_collection1_item1)
    assert !@instance.valid?
  end

  # usage_frequencies()

  test "usage_frequencies() returns a value" do
    # Fully testing this won't be worthwhile, so we will just test that it
    # returns the expected type.
    reg_e  = registered_elements(:southwest_dc_subject)
    result = AscribedElement.usage_frequencies(element:    reg_e,
                                               start_time: Time.new(2022, 3, 5),
                                               end_time:   Time.now)
    assert_equal 0, result.length
  end

  # date()

  test "date() returns a valid instance with a string containing ISO 8601" do
    @instance.string = "1968-02-12T00:12:25Z"
    assert_equal Date.new(1968, 2, 12), @instance.date
  end

  test "date() returns a valid instance with a string containing YYYY" do
    @instance.string = "1968"
    assert_equal Date.new(1968, 1, 1), @instance.date
  end

  test "date() returns a valid instance with a string containing YYYY-MM" do
    @instance.string = "1968-02"
    assert_equal Date.new(1968, 2, 1), @instance.date
  end

  test "date() returns a valid instance with a string containing YYYY-MM-DD" do
    @instance.string = "1968-02-25"
    assert_equal Date.new(1968, 2, 25), @instance.date
  end

  test "date() returns a valid instance with a string containing MM/DD/YY" do
    @instance.string = "3/23/92"
    assert_equal Date.new(1992, 3, 23), @instance.date
  end

  test "date() returns a valid instance with a string containing MM/DD/YYYY" do
    @instance.string = "3/23/1992"
    assert_equal Date.new(1992, 3, 23), @instance.date
  end

  test "date() returns a valid instance with a string containing Month DD YYYY" do
    @instance.string = "Oct 23 1992"
    assert_equal Date.new(1992, 10, 23), @instance.date
  end

  test "date() returns a valid instance with a string containing Month DD, YYYY" do
    @instance.string = "Oct 23, 1992"
    assert_equal Date.new(1992, 10, 23), @instance.date
  end

  test "date() returns a valid instance with a string containing Month YYYY" do
    @instance.string = "Sep 1993"
    assert_equal Date.new(1993, 9, 1), @instance.date
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

  # position

  test "position must be greater than or equal to 1" do
    assert @instance.valid?
    @instance.position = -1
    assert !@instance.valid?
    @instance.position = 0
    assert !@instance.valid?
    @instance.position = 1
    assert @instance.valid?
  end

  # string

  test "string is normalized" do
    @instance.string = " test  test "
    assert_equal "test  test", @instance.string
  end

  # uri

  test "uri is normalized" do
    @instance.uri = " test  test "
    assert_equal "test test", @instance.uri
  end

end
