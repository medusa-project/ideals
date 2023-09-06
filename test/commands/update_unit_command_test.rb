require 'test_helper'

class UpdateUnitCommandTest < ActiveSupport::TestCase

  test "execute() creates an associated Event" do
    Event.destroy_all

    user    = users(:southwest_admin)
    unit    = units(:southwest_unit1)
    command = UpdateUnitCommand.new(user: user, unit: unit)
    command.execute do
      unit.update!(title: "New Title")
    end

    event = Event.all.first
    assert_equal Event::Type::UPDATE, event.event_type
    assert_equal unit.institution, event.institution
    assert_equal unit, event.unit
    assert_equal user, event.user
    assert_not_nil event.before_changes
    assert_not_nil event.after_changes
    assert_not_equal event.before_changes, event.after_changes
  end

end
