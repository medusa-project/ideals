require 'test_helper'

class EventTest < ActiveSupport::TestCase

  class MockAuditable
    include Auditable
    def attributes
      [["key1", "value1"], ["key2", "value2"]]
    end
  end

  class TypeTest < ActiveSupport::TestCase

    test "all() returns all types" do
      assert_equal [0, 1, 2, 3], Event::Type::all.sort
    end

    test "label() raises an error for an invalid type" do
      assert_raises ArgumentError do
        Event::Type.label(840)
      end
    end

    test "label() returns a correct label" do
      assert_equal "Delete", Event::Type.label(Event::Type::DELETE)
    end
  end

  setup do
    @instance = events(:item1_create)
    assert @instance.valid?
  end

  # instance-level tests

  test "instance must be associated with an object" do
    @instance.bitstream = nil
    @instance.item      = nil
    assert !@instance.valid?

    @instance.item = items(:item1)
    assert @instance.valid?

    @instance.bitstream = bitstreams(:item1_in_staging)
    @instance.item      = nil
    assert @instance.valid?
  end

  # after_changes

  test "after_changes must contain valid JSON" do
    @instance.write_attribute(:after_changes, '{ "this": "is json" }')
    assert @instance.valid?
    @instance.write_attribute(:after_changes, "this is not json")
    assert !@instance.valid?
  end

  # after_changes=()

  test "after_changes=() serializes the column value" do
    @instance.after_changes = MockAuditable.new
    assert_equal '{"key1":"value1","key2":"value2"}',
                 @instance.read_attribute(:after_changes)
  end

  test "after_changes=() accepts a hash" do
    @instance.after_changes = { key1: "value1", key2: "value2" }
    assert_equal '{"key1":"value1","key2":"value2"}',
                 @instance.read_attribute(:after_changes)
  end

  # after_changes()

  test "after_changes() deserializes the column value" do
    @instance.after_changes = MockAuditable.new
    assert_equal({"key1" => "value1", "key2" => "value2"},
                 @instance.after_changes)
  end

  # before_changes

  test "before_changes must contain valid JSON" do
    @instance.write_attribute(:before_changes, '{ "this": "is json" }')
    assert @instance.valid?
    @instance.write_attribute(:before_changes, "this is not json")
    assert !@instance.valid?
  end

  # before_changes=()

  test "before_changes=() serializes the column value" do
    @instance.before_changes = MockAuditable.new
    assert_equal '{"key1":"value1","key2":"value2"}',
                 @instance.read_attribute(:before_changes)
  end

  test "before_changes=() accepts a hash" do
    @instance.before_changes = { key1: "value1", key2: "value2" }
    assert_equal '{"key1":"value1","key2":"value2"}',
                 @instance.read_attribute(:before_changes)
  end

  # before_changes()

  test "before_changes() deserializes the column value" do
    @instance.before_changes = MockAuditable.new
    assert_equal({"key1" => "value1", "key2" => "value2"},
                 @instance.before_changes)
  end

  # event_type

  test "event_type must be a valid type" do
    @instance.event_type = 750
    assert !@instance.valid?
  end

end
