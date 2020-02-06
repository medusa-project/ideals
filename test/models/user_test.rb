require 'test_helper'

class UserTest < ActiveSupport::TestCase

  setup do
    @instance = users(:norights)
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

  # role?()

  test "role?() returns true when the user is a member of the given role" do
    assert users(:admin).role?(:sysadmin)
  end

  test "role?() returns false when the user is not a member of the given role" do
    assert !@instance.role?(:sysadmin)
  end

  # roles

  test "roles can be empty" do
    @instance.roles = []
    assert @instance.save
  end

  test "user cannot be added to multiple instances of the same role" do
    @instance.roles = []
    role = roles(:sysadmin)
    @instance.roles << role
    assert_raises ActiveRecord::RecordNotUnique do
      @instance.roles << role
    end
  end

  # sysadmin?()

  test "sysadmin?() returns true when the user is a member of the sysadmin role" do
    assert users(:admin).sysadmin?
  end

  test "sysadmin?() returns false when the user is not a member of the sysadmin role" do
    assert !@instance.sysadmin?
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
