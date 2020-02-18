require 'test_helper'

class UserPolicyTest < ActiveSupport::TestCase

  setup do
    @object_user = users(:sally)
  end

  # edit?()

  test "edit?() with a nil subject user" do
    policy = UserPolicy.new(nil, @object_user)
    assert !policy.edit?
  end

  test "edit?() does not authorize non-sysadmins" do
    policy = UserPolicy.new(users(:norights), @object_user)
    assert !policy.edit?
  end

  test "edit?() authorizes sysadmins" do
    policy = UserPolicy.new(users(:admin), @object_user)
    assert policy.edit?
  end

  # index?()

  test "index?() with a nil subject user" do
    policy = UserPolicy.new(nil, @object_user)
    assert !policy.index?
  end

  test "index?() does not authorize non-sysadmins" do
    policy = UserPolicy.new(users(:norights), @object_user)
    assert !policy.index?
  end

  test "index?() authorizes sysadmins" do
    policy = UserPolicy.new(users(:admin), @object_user)
    assert policy.index?
  end

  # show?()

  test "show?() with a nil subject user" do
    policy = UserPolicy.new(nil, @object_user)
    assert !policy.show?
  end

  test "show?() does not authorize non-sysadmins" do
    policy = UserPolicy.new(users(:norights), @object_user)
    assert !policy.show?
  end

  test "show?() authorizes sysadmins" do
    policy = UserPolicy.new(users(:admin), @object_user)
    assert policy.show?
  end

  # update?()

  test "update?() with a nil subject user" do
    policy = UserPolicy.new(nil, @object_user)
    assert !policy.update?
  end

  test "update?() does not authorize non-sysadmins" do
    policy = UserPolicy.new(users(:norights), @object_user)
    assert !policy.update?
  end

  test "update?() authorizes sysadmins" do
    policy = UserPolicy.new(users(:admin), @object_user)
    assert policy.update?
  end

end
