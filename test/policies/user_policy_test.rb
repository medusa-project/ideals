require 'test_helper'

class UserPolicyTest < ActiveSupport::TestCase

  setup do
    @object_user = users(:sally)
  end

  # edit?()

  test "edit?() does not authorize non-sysadmins" do
    policy = UserPolicy.new(users(:norights), @object_user)
    assert !policy.edit?
  end

  test "edit?() authorizes sysadmins" do
    policy = UserPolicy.new(users(:admin), @object_user)
    assert policy.edit?
  end

  # index?()

  test "index?() does not authorize non-sysadmins" do
    policy = UserPolicy.new(users(:norights), @object_user)
    assert !policy.index?
  end

  test "index?() authorizes sysadmins" do
    policy = UserPolicy.new(users(:admin), @object_user)
    assert policy.index?
  end

  # show?()

  test "show?() does not authorize non-sysadmins" do
    policy = UserPolicy.new(users(:norights), @object_user)
    assert !policy.show?
  end

  test "show?() authorizes sysadmins" do
    policy = UserPolicy.new(users(:admin), @object_user)
    assert policy.show?
  end

  # update?()

  test "update?() does not authorize non-sysadmins" do
    policy = UserPolicy.new(users(:norights), @object_user)
    assert !policy.update?
  end

  test "update?() authorizes sysadmins" do
    policy = UserPolicy.new(users(:admin), @object_user)
    assert policy.update?
  end

end
