require 'test_helper'

class InviteePolicyTest < ActiveSupport::TestCase

  setup do
    @invitee = invitees(:norights)
  end

  # create?()

  test "create?() returns false with a nil user" do
    policy = InviteePolicy.new(nil, @invitee)
    assert !policy.create?
  end

  test "create?() does not authorize non-sysadmins" do
    context = UserContext.new(users(:norights), Role::NO_LIMIT)
    policy  = InviteePolicy.new(context, @invitee)
    assert !policy.create?
  end

  test "create?() authorizes sysadmins" do
    context = UserContext.new(users(:admin), Role::NO_LIMIT)
    policy  = InviteePolicy.new(context, @invitee)
    assert policy.create?
  end

  test "create?() respects role limits" do
    # sysadmin user limited to an insufficient role
    context = UserContext.new(users(:admin), Role::LOGGED_IN)
    policy  = InviteePolicy.new(context, @item)
    assert !policy.create?
  end

  # destroy?()

  test "destroy?() returns false with a nil user" do
    policy = InviteePolicy.new(nil, @invitee)
    assert !policy.destroy?
  end

  test "destroy?() does not authorize non-sysadmins" do
    context = UserContext.new(users(:norights), Role::NO_LIMIT)
    policy  = InviteePolicy.new(context, @invitee)
    assert !policy.destroy?
  end

  test "destroy?() authorizes sysadmins" do
    context = UserContext.new(users(:admin), Role::NO_LIMIT)
    policy  = InviteePolicy.new(context, @invitee)
    assert policy.destroy?
  end

  test "destroy?() respects role limits" do
    # sysadmin user limited to an insufficient role
    context = UserContext.new(users(:admin), Role::LOGGED_IN)
    policy  = InviteePolicy.new(context, @item)
    assert !policy.destroy?
  end

  # index?()

  test "index?() returns false with a nil user" do
    policy = InviteePolicy.new(nil, @invitee)
    assert !policy.index?
  end

  test "index?() does not authorize non-sysadmins" do
    context = UserContext.new(users(:norights), Role::NO_LIMIT)
    policy = InviteePolicy.new(context, @invitee)
    assert !policy.index?
  end

  test "index?() authorizes sysadmins" do
    context = UserContext.new(users(:admin), Role::NO_LIMIT)
    policy = InviteePolicy.new(context, @invitee)
    assert policy.index?
  end

  test "index?() respects role limits" do
    # sysadmin user limited to an insufficient role
    context = UserContext.new(users(:admin), Role::LOGGED_IN)
    policy  = InviteePolicy.new(context, @item)
    assert !policy.index?
  end

  # new?()

  test "new?() returns true with a nil user" do
    policy = InviteePolicy.new(nil, @invitee)
    assert policy.new?
  end

  test "new?() authorizes non-sysadmins" do
    context = UserContext.new(users(:norights), Role::NO_LIMIT)
    policy  = InviteePolicy.new(context, @invitee)
    assert policy.new?
  end

  test "new?() respects role limits" do
    # sysadmin user limited to an insufficient role
    context = UserContext.new(users(:admin), Role::LOGGED_OUT)
    policy  = InviteePolicy.new(context, @item)
    assert policy.new?
  end

  # update?()

  test "update?() returns false with a nil user" do
    policy = InviteePolicy.new(nil, @invitee)
    assert !policy.update?
  end

  test "update?() does not authorize non-sysadmins" do
    context = UserContext.new(users(:norights), Role::NO_LIMIT)
    policy  = InviteePolicy.new(context, @invitee)
    assert !policy.update?
  end

  test "update?() authorizes sysadmins" do
    context = UserContext.new(users(:admin), Role::NO_LIMIT)
    policy = InviteePolicy.new(context, @invitee)
    assert policy.update?
  end

  test "update?() respects role limits" do
    # sysadmin user limited to an insufficient role
    context = UserContext.new(users(:admin), Role::LOGGED_IN)
    policy  = InviteePolicy.new(context, @item)
    assert !policy.update?
  end

end
