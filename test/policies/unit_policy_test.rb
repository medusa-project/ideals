require 'test_helper'

class UnitPolicyTest < ActiveSupport::TestCase

  setup do
    @unit = units(:unit1)
  end

  # change_parent?()

  test "change_parent?() returns false with a nil user" do
    unit2 = units(:unit2)
    policy = UnitPolicy.new(nil, @unit)
    assert !policy.change_parent?(unit2.id)
  end

  test "change_parent?() is restrictive by default" do
    context = UserContext.new(users(:norights), Role::NO_LIMIT)
    unit2 = units(:unit2)
    policy = UnitPolicy.new(context, @unit)
    assert !policy.change_parent?(unit2.id)
  end

  test "change_parent?() authorizes sysadmins" do
    context = UserContext.new(users(:admin), Role::NO_LIMIT)
    unit2 = units(:unit2)
    policy = UnitPolicy.new(context, @unit)
    assert policy.change_parent?(unit2.id)
  end

  test "change_parent?() respects role limits" do
    # sysadmin user limited to an insufficient role
    context = UserContext.new(users(:admin), Role::LOGGED_IN)
    unit2 = units(:unit2)
    policy  = UnitPolicy.new(context, @unit)
    assert !policy.change_parent?(unit2.id)
  end

  # children?()

  test "children?() returns true with a nil user" do
    policy = UnitPolicy.new(nil, @unit)
    assert policy.children?
  end

  test "children?() authorizes everyone" do
    context = UserContext.new(users(:norights), Role::NO_LIMIT)
    policy  = UnitPolicy.new(context, @unit)
    assert policy.children?
  end

  # collections?()

  test "collections?() returns true with a nil user" do
    policy = UnitPolicy.new(nil, @unit)
    assert policy.collections?
  end

  test "collections?() authorizes everyone" do
    context = UserContext.new(users(:norights), Role::NO_LIMIT)
    policy  = UnitPolicy.new(context, @unit)
    assert policy.collections?
  end

  # create?()

  test "create?() returns false with a nil user" do
    policy = UnitPolicy.new(nil, @unit)
    assert !policy.create?
  end

  test "create?() is restrictive by default" do
    context = UserContext.new(users(:norights), Role::NO_LIMIT)
    policy  = UnitPolicy.new(context, @unit)
    assert !policy.create?
  end

  test "create?() authorizes sysadmins" do
    context = UserContext.new(users(:admin), Role::NO_LIMIT)
    policy  = UnitPolicy.new(context, @unit)
    assert policy.create?
  end

  test "create?() authorizes institution admins" do
    context = UserContext.new(users(:somewhere_admin), Role::NO_LIMIT)
    policy  = UnitPolicy.new(context, @unit)
    assert policy.create?
  end

  test "create?() respects role limits" do
    # sysadmin user limited to an insufficient role
    context = UserContext.new(users(:admin), Role::LOGGED_IN)
    policy  = UnitPolicy.new(context, @unit)
    assert !policy.create?
  end

  # destroy?()

  test "destroy?() returns false with a nil user" do
    policy = UnitPolicy.new(nil, @unit)
    assert !policy.destroy?
  end

  test "destroy?() is restrictive by default" do
    context = UserContext.new(users(:norights), Role::NO_LIMIT)
    policy = UnitPolicy.new(context, @unit)
    assert !policy.destroy?
  end

  test "destroy?() authorizes sysadmins" do
    context = UserContext.new(users(:admin), Role::NO_LIMIT)
    policy  = UnitPolicy.new(context, @unit)
    assert policy.destroy?
  end

  test "destroy?() respects role limits" do
    # sysadmin user limited to an insufficient role
    context = UserContext.new(users(:admin), Role::LOGGED_IN)
    policy  = UnitPolicy.new(context, @unit)
    assert !policy.destroy?
  end

  # edit_access?()

  test "edit_access?() returns false with a nil user" do
    policy = UnitPolicy.new(nil, @unit)
    assert !policy.edit_access?
  end

  test "edit_access?() is restrictive by default" do
    context = UserContext.new(users(:norights), Role::NO_LIMIT)
    policy  = UnitPolicy.new(context, @unit)
    assert !policy.edit_access?
  end

  test "edit_access?() authorizes sysadmins" do
    context = UserContext.new(users(:admin), Role::NO_LIMIT)
    policy = UnitPolicy.new(context, @unit)
    assert policy.edit_access?
  end

  test "edit_access?() respects role limits" do
    # sysadmin user limited to an insufficient role
    context = UserContext.new(users(:admin), Role::LOGGED_IN)
    policy  = UnitPolicy.new(context, @unit)
    assert !policy.edit_access?
  end

  # edit_membership?()

  test "edit_membership?() returns false with a nil user" do
    policy = UnitPolicy.new(nil, @unit)
    assert !policy.edit_membership?
  end

  test "edit_membership?() is restrictive by default" do
    context = UserContext.new(users(:norights), Role::NO_LIMIT)
    policy  = UnitPolicy.new(context, @unit)
    assert !policy.edit_membership?
  end

  test "edit_membership?() authorizes sysadmins" do
    context = UserContext.new(users(:admin), Role::NO_LIMIT)
    policy  = UnitPolicy.new(context, @unit)
    assert policy.edit_membership?
  end

  test "edit_membership?() respects role limits" do
    # sysadmin user limited to an insufficient role
    context = UserContext.new(users(:admin), Role::LOGGED_IN)
    policy  = UnitPolicy.new(context, @unit)
    assert !policy.edit_membership?
  end

  # edit_properties?()

  test "edit_properties?() returns false with a nil user" do
    policy = UnitPolicy.new(nil, @unit)
    assert !policy.edit_properties?
  end

  test "edit_properties?() is restrictive by default" do
    context = UserContext.new(users(:norights), Role::NO_LIMIT)
    policy = UnitPolicy.new(context, @unit)
    assert !policy.edit_properties?
  end

  test "edit_properties?() authorizes sysadmins" do
    context = UserContext.new(users(:admin), Role::NO_LIMIT)
    policy = UnitPolicy.new(context, @unit)
    assert policy.edit_properties?
  end

  test "edit_properties?() respects role limits" do
    # sysadmin user limited to an insufficient role
    context = UserContext.new(users(:admin), Role::LOGGED_IN)
    policy  = UnitPolicy.new(context, @unit)
    assert !policy.edit_properties?
  end

  # index?()

  test "index?() returns true with a nil user" do
    policy = UnitPolicy.new(nil, Unit)
    assert policy.index?
  end

  test "index?() authorizes everyone" do
    context = UserContext.new(users(:norights), Role::NO_LIMIT)
    policy  = UnitPolicy.new(context, Unit)
    assert policy.index?
  end

  # new?()

  test "new?() returns false with a nil user" do
    policy = UnitPolicy.new(nil, @unit)
    assert !policy.new?
  end

  test "new?() is restrictive by default" do
    context = UserContext.new(users(:norights), Role::NO_LIMIT)
    policy  = UnitPolicy.new(context, @unit)
    assert !policy.new?
  end

  test "new?() returns true when the target object is a Unit" do
    context = UserContext.new(users(:admin), Role::NO_LIMIT)
    policy  = UnitPolicy.new(context, Unit)
    assert policy.new?
  end

  test "new?() authorizes sysadmins" do
    context = UserContext.new(users(:admin), Role::NO_LIMIT)
    policy = UnitPolicy.new(context, @unit)
    assert policy.new?
  end

  test "new?() respects role limits" do
    # sysadmin user limited to an insufficient role
    context = UserContext.new(users(:admin), Role::LOGGED_IN)
    policy  = UnitPolicy.new(context, @unit)
    assert !policy.new?
  end

  # show?()

  test "show?() returns true with a nil user" do
    policy = UnitPolicy.new(nil, @unit)
    assert policy.show?
  end

  test "show?() authorizes everyone" do
    context = UserContext.new(users(:norights), Role::NO_LIMIT)
    policy  = UnitPolicy.new(context, @unit)
    assert policy.show?
  end

  # update?()

  test "update?() returns false with a nil user" do
    policy = UnitPolicy.new(nil, @unit)
    assert !policy.update?
  end

  test "update?() is restrictive by default" do
    context = UserContext.new(users(:norights), Role::NO_LIMIT)
    policy = UnitPolicy.new(context, @unit)
    assert !policy.update?
  end

  test "update?() authorizes sysadmins" do
    context = UserContext.new(users(:admin), Role::NO_LIMIT)
    policy = UnitPolicy.new(context, @unit)
    assert policy.update?
  end

  test "update?() respects role limits" do
    # sysadmin user limited to an insufficient role
    context = UserContext.new(users(:admin), Role::LOGGED_IN)
    policy  = UnitPolicy.new(context, @unit)
    assert !policy.update?
  end

end
