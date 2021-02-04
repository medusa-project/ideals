require 'test_helper'

class UpdateItemCommandTest < ActiveSupport::TestCase

  test "execute() creates an associated Event" do
    Event.destroy_all

    user        = users(:local_sysadmin)
    item        = items(:item1)
    description = "I just updated this item"
    command     = UpdateItemCommand.new(item: item,
                                        user: user,
                                        description: description)
    command.execute do
      item.update!(stage: Item::Stages::REJECTED)
    end

    event = Event.all.first
    assert_equal Event::Type::UPDATE, event.event_type
    assert_equal item, event.item
    assert_equal user, event.user
    assert_not_nil event.before_changes
    assert_not_nil event.after_changes
  end

end
