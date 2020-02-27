require 'test_helper'

class UnitPolicyTest < ActiveSupport::TestCase

  setup do
    @unit = units(:unit1)
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

  # edit?()

  test "edit?() returns false with a nil user" do
    policy = UnitPolicy.new(nil, @unit)
    assert !policy.edit?
  end

  test "edit?() is restrictive by default" do
    policy = UnitPolicy.new(users(:norights), @unit)
    assert !policy.edit?
  end

  test "edit?() returns false when the target object is a Unit" do
    policy = UnitPolicy.new(users(:admin), Unit)
    assert !policy.edit?
  end

  test "edit?() authorizes sysadmins" do
    policy = UnitPolicy.new(users(:admin), @unit)
    assert policy.edit?
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
