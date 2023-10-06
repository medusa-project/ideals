require 'test_helper'

class ImportItemCommandTest < ActiveSupport::TestCase

  test "execute() returns the expected instance" do
    collection = collections(:southeast_collection1)
    command    = ImportItemCommand.new(primary_collection: collection)
    item       = command.execute
    assert_equal Item::Stages::APPROVED, item.stage
    assert_equal collection.institution, item.institution
  end

  test "execute() creates an associated Event" do
    command = ImportItemCommand.new(primary_collection: collections(:southeast_collection1))
    item    = command.execute

    event = Event.order(updated_at: :desc).first
    assert_equal Event::Type::CREATE, event.event_type
    assert_equal item, event.item
    assert_equal item.as_change_hash, event.after_changes
  end

end
