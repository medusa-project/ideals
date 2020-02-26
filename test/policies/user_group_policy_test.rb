require 'test_helper'

class UserGroupPolicyTest < ActiveSupport::TestCase

  setup do
    @user_group = user_groups(:one)
  end

  # create?()

  test "create?() does not authorize non-sysadmins" do
    policy = UserGroupPolicy.new(users(:norights), @user)
    assert !policy.create?
  end

  test "create?() authorizes sysadmins" do
    policy = UserGroupPolicy.new(users(:admin), @user)
    assert policy.create?
  end

  # destroy?()

  test "destroy?() does not authorize non-sysadmins" do
    policy = UserGroupPolicy.new(users(:norights), @user)
    assert !policy.destroy?
  end

  test "destroy?() authorizes sysadmins" do
    policy = UserGroupPolicy.new(users(:admin), @user)
    assert policy.edit?
  end

  # edit?()

  test "edit?() does not authorize non-sysadmins" do
    policy = UserGroupPolicy.new(users(:norights), @user)
    assert !policy.edit?
  end

  test "edit?() authorizes sysadmins" do
    policy = UserGroupPolicy.new(users(:admin), @user)
    assert policy.edit?
  end

  # index?()

  test "index?() does not authorize non-sysadmins" do
    policy = UserGroupPolicy.new(users(:norights), @user)
    assert !policy.index?
  end

  test "index?() authorizes sysadmins" do
    policy = UserGroupPolicy.new(users(:admin), @user)
    assert policy.index?
  end

  # new()

  test "new?() does not authorize non-sysadmins" do
    policy = UserGroupPolicy.new(users(:norights), @user)
    assert !policy.new?
  end

  test "new?() authorizes sysadmins" do
    policy = UserGroupPolicy.new(users(:admin), @user)
    assert policy.new?
  end

  # show?()

  test "show?() does not authorize non-sysadmins" do
    policy = UserGroupPolicy.new(users(:norights), @user)
    assert !policy.show?
  end

  test "show?() authorizes sysadmins" do
    policy = UserGroupPolicy.new(users(:admin), @user)
    assert policy.show?
  end

  # update?()

  test "update?() does not authorize non-sysadmins" do
    policy = UserGroupPolicy.new(users(:norights), @user)
    assert !policy.update?
  end

  test "update?() authorizes sysadmins" do
    policy = UserGroupPolicy.new(users(:admin), @user)
    assert policy.update?
  end

end
