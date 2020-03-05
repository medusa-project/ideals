require 'test_helper'

class RegisteredElementPolicyTest < ActiveSupport::TestCase

  setup do
    @user    = users(:sally)
    @element = registered_elements(:title)
  end

  # create?()

  test "create?() returns false with a nil user" do
    policy = RegisteredElementPolicy.new(nil, @element)
    assert !policy.create?
  end

  test "create?() does not authorize non-sysadmins" do
    policy = RegisteredElementPolicy.new(users(:norights), @element)
    assert !policy.create?
  end

  test "create?() authorizes sysadmins" do
    policy = RegisteredElementPolicy.new(users(:admin), @element)
    assert policy.create?
  end

  # destroy?()

  test "destroy?() returns false with a nil user" do
    policy = RegisteredElementPolicy.new(nil, @element)
    assert !policy.destroy?
  end

  test "destroy?() does not authorize non-sysadmins" do
    policy = RegisteredElementPolicy.new(users(:norights), @element)
    assert !policy.destroy?
  end

  test "destroy?() authorizes sysadmins" do
    policy = RegisteredElementPolicy.new(users(:admin), @element)
    assert policy.destroy?
  end

  # edit?()

  test "edit?() returns false with a nil user" do
    policy = RegisteredElementPolicy.new(nil, @element)
    assert !policy.edit?
  end

  test "edit?() does not authorize non-sysadmins" do
    policy = RegisteredElementPolicy.new(users(:norights), @element)
    assert !policy.edit?
  end

  test "edit?() authorizes sysadmins" do
    policy = RegisteredElementPolicy.new(users(:admin), @element)
    assert policy.edit?
  end

  # index?()

  test "index?() returns false with a nil user" do
    policy = RegisteredElementPolicy.new(nil, RegisteredElement)
    assert !policy.index?
  end

  test "index?() does not authorize non-sysadmins" do
    policy = RegisteredElementPolicy.new(users(:norights), RegisteredElement)
    assert !policy.index?
  end

  test "index?() authorizes sysadmins" do
    policy = RegisteredElementPolicy.new(users(:admin), RegisteredElement)
    assert policy.index?
  end

  # new()

  test "new?() returns false with a nil user" do
    policy = RegisteredElementPolicy.new(nil, @element)
    assert !policy.new?
  end

  test "new?() does not authorize non-sysadmins" do
    policy = RegisteredElementPolicy.new(users(:norights), @element)
    assert !policy.new?
  end

  test "new?() authorizes sysadmins" do
    policy = RegisteredElementPolicy.new(users(:admin), @element)
    assert policy.new?
  end

  # show?()

  test "show?() returns false with a nil user" do
    policy = RegisteredElementPolicy.new(nil, @element)
    assert !policy.show?
  end

  test "show?() does not authorize non-sysadmins" do
    policy = RegisteredElementPolicy.new(users(:norights), @element)
    assert !policy.show?
  end

  test "show?() authorizes sysadmins" do
    policy = RegisteredElementPolicy.new(users(:admin), @element)
    assert policy.show?
  end

  # update?()

  test "update?() returns false with a nil user" do
    policy = RegisteredElementPolicy.new(nil, @element)
    assert !policy.update?
  end

  test "update?() does not authorize non-sysadmins" do
    policy = RegisteredElementPolicy.new(users(:norights), @element)
    assert !policy.update?
  end

  test "update?() authorizes sysadmins" do
    policy = RegisteredElementPolicy.new(users(:admin), @element)
    assert policy.update?
  end

end
