require 'test_helper'

class CreateUnitCommandTest < ActiveSupport::TestCase

  test "execute() persists the instance" do
    unit = Unit.new(title:       "New Unit",
                    institution: institutions(:southwest))
    command    = CreateUnitCommand.new(user: users(:southwest_admin),
                                       unit: unit)
    command.execute

    assert unit.persisted?
  end

  test "execute() creates an associated Event" do
    Event.destroy_all
    user = users(:southwest_admin)
    unit = Unit.new(title:       "New Unit",
                    institution: institutions(:southwest))
    command    = CreateUnitCommand.new(user: user,
                                       unit: unit)
    command.execute

    event = Event.all.first
    assert_equal Event::Type::CREATE, event.event_type
    assert_equal unit, event.unit
    assert_equal user, event.user
    assert_equal unit.as_change_hash, event.after_changes
  end

end
