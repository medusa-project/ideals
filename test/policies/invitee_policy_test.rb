require 'test_helper'

class InviteePolicyTest < ActiveSupport::TestCase

  setup do
    @invitee = invitees(:norights)
  end

  # approve?()

  test "approve?() returns false with a nil user" do
    policy = InviteePolicy.new(nil, @invitee)
    assert !policy.approve?
  end

  test "approve?() does not authorize non-sysadmins" do
    context = UserContext.new(users(:norights), Role::NO_LIMIT)
    policy  = InviteePolicy.new(context, @invitee)
    assert !policy.approve?
  end

  test "approve?() authorizes sysadmins" do
    context = UserContext.new(users(:local_sysadmin), Role::NO_LIMIT)
    policy  = InviteePolicy.new(context, @invitee)
    assert policy.approve?
  end

  test "approve?() respects role limits" do
    # sysadmin user limited to an insufficient role
    context = UserContext.new(users(:local_sysadmin), Role::LOGGED_IN)
    policy  = InviteePolicy.new(context, @item)
    assert !policy.approve?
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
    context = UserContext.new(users(:local_sysadmin), Role::NO_LIMIT)
    policy  = InviteePolicy.new(context, @invitee)
    assert policy.create?
  end

  test "create?() respects role limits" do
    # sysadmin user limited to an insufficient role
    context = UserContext.new(users(:local_sysadmin), Role::LOGGED_IN)
    policy  = InviteePolicy.new(context, @item)
    assert !policy.create?
  end

  # create_unsolicited?()

  test "create_unsolicited?() returns true with a nil user" do
    policy = InviteePolicy.new(nil, @invitee)
    assert policy.create_unsolicited?
  end

  test "create_unsolicited?() does not authorize logged-in users" do
    context = UserContext.new(users(:norights), Role::NO_LIMIT)
    policy  = InviteePolicy.new(context, @invitee)
    assert !policy.create_unsolicited?
  end

  test "create_unsolicited?() authorizes non-logged-in users" do
    context = UserContext.new(nil, Role::NO_LIMIT)
    policy  = InviteePolicy.new(context, @invitee)
    assert policy.create_unsolicited?
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
    context = UserContext.new(users(:local_sysadmin), Role::NO_LIMIT)
    policy  = InviteePolicy.new(context, @invitee)
    assert policy.destroy?
  end

  test "destroy?() respects role limits" do
    # sysadmin user limited to an insufficient role
    context = UserContext.new(users(:local_sysadmin), Role::LOGGED_IN)
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
    context = UserContext.new(users(:local_sysadmin), Role::NO_LIMIT)
    policy = InviteePolicy.new(context, @invitee)
    assert policy.index?
  end

  test "index?() respects role limits" do
    # sysadmin user limited to an insufficient role
    context = UserContext.new(users(:local_sysadmin), Role::LOGGED_IN)
    policy  = InviteePolicy.new(context, @item)
    assert !policy.index?
  end

  # new?()

  test "new?() returns true with a nil user" do
    policy = InviteePolicy.new(nil, @invitee)
    assert policy.new?
  end

  test "new?() does not authorize logged-in users" do
    context = UserContext.new(nil, Role::NO_LIMIT)
    policy  = InviteePolicy.new(context, @invitee)
    assert policy.new?
  end

  test "new?() authorizes non-logged-in users" do
    context = UserContext.new(nil, Role::NO_LIMIT)
    policy  = InviteePolicy.new(context, @invitee)
    assert policy.new?
  end

  # reject?()

  test "reject?() returns false with a nil user" do
    policy = InviteePolicy.new(nil, @invitee)
    assert !policy.reject?
  end

  test "reject?() does not authorize non-sysadmins" do
    context = UserContext.new(users(:norights), Role::NO_LIMIT)
    policy  = InviteePolicy.new(context, @invitee)
    assert !policy.reject?
  end

  test "reject?() authorizes sysadmins" do
    context = UserContext.new(users(:local_sysadmin), Role::NO_LIMIT)
    policy  = InviteePolicy.new(context, @invitee)
    assert policy.reject?
  end

  test "reject?() respects role limits" do
    # sysadmin user limited to an insufficient role
    context = UserContext.new(users(:local_sysadmin), Role::LOGGED_IN)
    policy  = InviteePolicy.new(context, @item)
    assert !policy.reject?
  end

  # resend_email?()

  test "resend_email?() returns false with a nil user" do
    policy = InviteePolicy.new(nil, @invitee)
    assert !policy.resend_email?
  end

  test "resend_email?() does not authorize non-sysadmins" do
    context = UserContext.new(users(:norights), Role::NO_LIMIT)
    policy  = InviteePolicy.new(context, @invitee)
    assert !policy.resend_email?
  end

  test "resend_email?() authorizes sysadmins" do
    context = UserContext.new(users(:local_sysadmin), Role::NO_LIMIT)
    policy  = InviteePolicy.new(context, @invitee)
    assert policy.resend_email?
  end

  test "resend_email?() respects role limits" do
    # sysadmin user limited to an insufficient role
    context = UserContext.new(users(:local_sysadmin), Role::LOGGED_IN)
    policy  = InviteePolicy.new(context, @item)
    assert !policy.resend_email?
  end

  # show?()

  test "show?() returns false with a nil user" do
    policy = InviteePolicy.new(nil, @invitee)
    assert !policy.show?
  end

  test "show?() does not authorize non-sysadmins" do
    context = UserContext.new(users(:norights), Role::NO_LIMIT)
    policy = InviteePolicy.new(context, @invitee)
    assert !policy.show?
  end

  test "show?() authorizes sysadmins" do
    context = UserContext.new(users(:local_sysadmin), Role::NO_LIMIT)
    policy = InviteePolicy.new(context, @invitee)
    assert policy.show?
  end

  test "show?() respects role limits" do
    # sysadmin user limited to an insufficient role
    context = UserContext.new(users(:local_sysadmin), Role::LOGGED_IN)
    policy  = InviteePolicy.new(context, @item)
    assert !policy.show?
  end

end
