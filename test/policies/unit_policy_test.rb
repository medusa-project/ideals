require 'test_helper'

class UnitPolicyTest < ActiveSupport::TestCase

  setup do
    @unit = units(:unit1)
  end

  # children?()

  test "children?() returns true with a nil user" do
    policy = UnitPolicy.new(nil, @unit)
    assert policy.children?
  end

  test "children?() authorizes everyone" do
    policy = UnitPolicy.new(users(:norights), @unit)
    assert policy.children?
  end

  # create?()

  test "create?() returns false with a nil user" do
    policy = UnitPolicy.new(nil, @unit)
    assert !policy.create?
  end

  test "create?() is restrictive by default" do
    policy = UnitPolicy.new(users(:norights), @unit)
    assert !policy.create?
  end

  test "create?() returns true when the target object is a Unit" do
    policy = UnitPolicy.new(users(:admin), Unit)
    assert policy.create?
  end

  test "create?() authorizes sysadmins" do
    policy = UnitPolicy.new(users(:admin), @unit)
    assert policy.create?
  end

  # destroy?()

  test "destroy?() returns false with a nil user" do
    policy = UnitPolicy.new(nil, @unit)
    assert !policy.destroy?
  end

  test "destroy?() is restrictive by default" do
    policy = UnitPolicy.new(users(:norights), @unit)
    assert !policy.destroy?
  end

  test "destroy?() returns false when the target object is a Unit" do
    policy = UnitPolicy.new(users(:admin), Unit)
    assert !policy.destroy?
  end

  test "destroy?() authorizes sysadmins" do
    policy = UnitPolicy.new(users(:admin), @unit)
    assert policy.destroy?
  end

  # edit_access?()

  test "edit_access?() returns false with a nil user" do
    policy = UnitPolicy.new(nil, @unit)
    assert !policy.edit_access?
  end

  test "edit_access?() is restrictive by default" do
    policy = UnitPolicy.new(users(:norights), @unit)
    assert !policy.edit_access?
  end

  test "edit_access?() returns false when the target object is a Unit" do
    policy = UnitPolicy.new(users(:admin), Unit)
    assert !policy.edit_access?
  end

  test "edit_access?() authorizes sysadmins" do
    policy = UnitPolicy.new(users(:admin), @unit)
    assert policy.edit_access?
  end

  # edit_membership?()

  test "edit_membership?() returns false with a nil user" do
    policy = UnitPolicy.new(nil, @unit)
    assert !policy.edit_membership?
  end

  test "edit_membership?() is restrictive by default" do
    policy = UnitPolicy.new(users(:norights), @unit)
    assert !policy.edit_membership?
  end

  test "edit_membership?() returns false when the target object is a Unit" do
    policy = UnitPolicy.new(users(:admin), Unit)
    assert !policy.edit_membership?
  end

  test "edit_membership?() authorizes sysadmins" do
    policy = UnitPolicy.new(users(:admin), @unit)
    assert policy.edit_membership?
  end

  # edit_properties?()

  test "edit_properties?() returns false with a nil user" do
    policy = UnitPolicy.new(nil, @unit)
    assert !policy.edit_properties?
  end

  test "edit_properties?() is restrictive by default" do
    policy = UnitPolicy.new(users(:norights), @unit)
    assert !policy.edit_properties?
  end

  test "edit_properties?() returns false when the target object is a Unit" do
    policy = UnitPolicy.new(users(:admin), Unit)
    assert !policy.edit_properties?
  end

  test "edit_properties?() authorizes sysadmins" do
    policy = UnitPolicy.new(users(:admin), @unit)
    assert policy.edit_properties?
  end

  # index?()

  test "index?() returns true with a nil user" do
    policy = UnitPolicy.new(nil, Unit)
    assert policy.index?
  end

  test "index?() authorizes everyone" do
    policy = UnitPolicy.new(users(:norights), Unit)
    assert policy.index?
  end

  # new?()

  test "new?() returns false with a nil user" do
    policy = UnitPolicy.new(nil, @unit)
    assert !policy.new?
  end

  test "new?() is restrictive by default" do
    policy = UnitPolicy.new(users(:norights), @unit)
    assert !policy.new?
  end

  test "new?() returns true when the target object is a Unit" do
    policy = UnitPolicy.new(users(:admin), Unit)
    assert policy.new?
  end

  test "new?() authorizes sysadmins" do
    policy = UnitPolicy.new(users(:admin), @unit)
    assert policy.new?
  end

  # show?()

  test "show?() returns true with a nil user" do
    policy = UnitPolicy.new(nil, @unit)
    assert policy.show?
  end

  test "show?() authorizes everyone" do
    policy = UnitPolicy.new(users(:norights), @unit)
    assert policy.show?
  end

  # update?()

  test "update?() returns false with a nil user" do
    policy = UnitPolicy.new(nil, @unit)
    assert !policy.update?
  end

  test "update?() is restrictive by default" do
    policy = UnitPolicy.new(users(:norights), @unit)
    assert !policy.update?
  end

  test "update?() returns false when the target object is a Unit" do
    policy = UnitPolicy.new(users(:admin), Unit)
    assert !policy.update?
  end

  test "update?() authorizes sysadmins" do
    policy = UnitPolicy.new(users(:admin), @unit)
    assert policy.update?
  end

end
