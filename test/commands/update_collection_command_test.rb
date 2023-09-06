require 'test_helper'

class UpdateCollectionCommandTest < ActiveSupport::TestCase

  test "execute() creates an associated Event" do
    Event.destroy_all

    user       = users(:southwest_admin)
    collection = collections(:southwest_unit1_collection1)
    command    = UpdateCollectionCommand.new(user: user, collection: collection)
    command.execute do
      collection.update!(title: "New Title")
    end

    event = Event.all.first
    assert_equal Event::Type::UPDATE, event.event_type
    assert_equal collection.institution, event.institution
    assert_equal collection, event.collection
    assert_equal user, event.user
    assert_not_nil event.before_changes
    assert_not_nil event.after_changes
    assert_not_equal event.before_changes, event.after_changes
  end

end
