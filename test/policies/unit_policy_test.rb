require 'test_helper'

class UnitPolicyTest < ActiveSupport::TestCase

  setup do
    @unit = units(:unit1)
  end

  # create?()

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

  test "index?() authorizes everyone" do
    policy = UnitPolicy.new(users(:norights), @unit)
    assert policy.index?
  end

  # new?()

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

  test "show?() authorizes everyone" do
    policy = UnitPolicy.new(users(:norights), @unit)
    assert policy.show?
  end

  # update?()

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
