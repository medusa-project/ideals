require 'test_helper'

class UserTest < ActiveSupport::TestCase

  setup do
    @instance = users(:norights)
  end

  # effective_manager?()

  test "effective_manager?() returns true when the user is a manager of the given collection" do
    collection = collections(:collection1)
    collection.managing_users << @instance
    collection.save!
    assert @instance.effective_manager?(collection)
  end

  test "effective_manager?() returns true when the user is an administrator of
  one of the collection's units" do
    collection = collections(:collection1)
    unit = collection.primary_unit
    unit.administering_users << @instance
    unit.save!
    assert @instance.effective_manager?(collection)
  end

  test "effective_manager?() returns true when the user is a sysadmin" do
    @instance = users(:admin)
    collection = collections(:collection1)
    assert @instance.effective_manager?(collection)
  end

  test "effective_manager?() returns false when the user is not a manager of
  the given collection, nor a unit admin, nor a sysadmin" do
    assert !@instance.effective_manager?(collections(:collection1))
  end

  # manager?()

  test "manager?() returns true when the user is a manager of the given collection" do
    collection = collections(:collection1)
    collection.managing_users << @instance
    collection.save!
    assert @instance.manager?(collection)
  end

  test "manager?() returns false when the user is not a manager of the given collection" do
    assert !@instance.manager?(collections(:collection1))
  end

  # unit_admin?()

  test "unit_admin?() returns true when the user is an administrator of the
  given unit" do
    unit = units(:unit1)
    unit.administering_users << @instance
    unit.save!
    assert @instance.unit_admin?(unit)
  end

  test "unit_admin?() returns false when the user is not an administrator of
  the given unit" do
    assert !@instance.unit_admin?(units(:unit1))
  end

end
