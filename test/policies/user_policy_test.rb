require 'test_helper'

class UserPolicyTest < ActiveSupport::TestCase

  setup do
    @object_user = users(:sally)
  end

  # edit?()

  test "edit?() returns false with a nil user context" do
    policy = UserPolicy.new(nil, @object_user)
    assert !policy.edit?
  end

  test "edit?() does not authorize non-sysadmins" do
    context = UserContext.new(users(:norights), Role::NO_LIMIT)
    policy  = UserPolicy.new(context, @object_user)
    assert !policy.edit?
  end

  test "edit?() authorizes sysadmins" do
    context = UserContext.new(users(:admin), Role::NO_LIMIT)
    policy = UserPolicy.new(context, @object_user)
    assert policy.edit?
  end

  test "edit?() respects role limits" do
    # sysadmin user limited to an insufficient role
    context = UserContext.new(users(:admin), Role::LOGGED_IN)
    policy  = UserPolicy.new(context, @object_user)
    assert !policy.edit?
  end

  # index?()

  test "index?() returns false with a nil user context" do
    policy = UserPolicy.new(nil, User)
    assert !policy.index?
  end

  test "index?() does not authorize non-sysadmins" do
    context = UserContext.new(users(:norights), Role::NO_LIMIT)
    policy  = UserPolicy.new(context, User)
    assert !policy.index?
  end

  test "index?() authorizes sysadmins" do
    context = UserContext.new(users(:admin), Role::NO_LIMIT)
    policy = UserPolicy.new(context, User)
    assert policy.index?
  end

  test "index?() respects role limits" do
    # sysadmin user limited to an insufficient role
    context = UserContext.new(users(:admin), Role::LOGGED_IN)
    policy  = UserPolicy.new(context, @object_user)
    assert !policy.index?
  end

  # show?()

  test "show?() returns false with a nil user context" do
    policy = UserPolicy.new(nil, @object_user)
    assert !policy.show?
  end

  test "show?() does not authorize non-sysadmins" do
    context = UserContext.new(users(:norights), Role::NO_LIMIT)
    policy = UserPolicy.new(context, @object_user)
    assert !policy.show?
  end

  test "show?() authorizes sysadmins" do
    context = UserContext.new(users(:admin), Role::NO_LIMIT)
    policy = UserPolicy.new(context, @object_user)
    assert policy.show?
  end

  test "show?() respects role limits" do
    # sysadmin user limited to an insufficient role
    context = UserContext.new(users(:admin), Role::LOGGED_IN)
    policy  = UserPolicy.new(context, @object_user)
    assert !policy.show?
  end

  # update?()

  test "update?() returns false with a nil user context" do
    policy = UserPolicy.new(nil, @object_user)
    assert !policy.update?
  end

  test "update?() does not authorize non-sysadmins" do
    context = UserContext.new(users(:norights), Role::NO_LIMIT)
    policy = UserPolicy.new(context, @object_user)
    assert !policy.update?
  end

  test "update?() authorizes sysadmins" do
    context = UserContext.new(users(:admin), Role::NO_LIMIT)
    policy = UserPolicy.new(context, @object_user)
    assert policy.update?
  end

  test "update?() respects role limits" do
    # sysadmin user limited to an insufficient role
    context = UserContext.new(users(:admin), Role::LOGGED_IN)
    policy  = UserPolicy.new(context, @object_user)
    assert !policy.update?
  end

end
