require 'test_helper'

class CreateCollectionCommandTest < ActiveSupport::TestCase

  test "execute() persists the instance" do
    collection = Collection.new(title:       "New Collection",
                                institution: institutions(:southwest))
    command    = CreateCollectionCommand.new(user:       users(:southwest_admin),
                                             collection: collection)
    command.execute

    assert collection.persisted?
  end

  test "execute() creates an associated Event" do
    Event.destroy_all
    user       = users(:southwest_admin)
    collection = Collection.new(title:       "New Collection",
                                institution: institutions(:southwest))
    command    = CreateCollectionCommand.new(user:       user,
                                             collection: collection)
    command.execute

    event = Event.all.first
    assert_equal Event::Type::CREATE, event.event_type
    assert_equal collection, event.collection
    assert_equal user, event.user
    assert_equal collection.as_change_hash, event.after_changes
  end

end
