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
    user    = users(:norights)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = InviteePolicy.new(context, @invitee)
    assert !policy.approve?
  end

  test "approve?() authorizes sysadmins" do
    user    = users(:local_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = InviteePolicy.new(context, @invitee)
    assert policy.approve?
  end

  test "approve?() authorizes administrators of the same institution" do
    user = users(:southwest_admin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = InviteePolicy.new(context, @element)
    assert policy.approve?
  end

  test "approve?() does not authorize administrators of a different
  institution" do
    user    = users(:southwest_admin)
    context = RequestContext.new(user:        user,
                                 institution: institutions(:northeast))
    policy  = InviteePolicy.new(context, @element)
    assert !policy.approve?
  end

  test "approve?() respects role limits" do
    # sysadmin user limited to an insufficient role
    user    = users(:local_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::LOGGED_IN)
    policy  = InviteePolicy.new(context, @item)
    assert !policy.approve?
  end

  # create?()

  test "create?() returns false with a nil user" do
    policy = InviteePolicy.new(nil, @invitee)
    assert !policy.create?
  end

  test "create?() does not authorize non-sysadmins" do
    user    = users(:norights)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = InviteePolicy.new(context, @invitee)
    assert !policy.create?
  end

  test "create?() authorizes sysadmins" do
    user    = users(:local_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = InviteePolicy.new(context, @invitee)
    assert policy.create?
  end

  test "create?() authorizes administrators of the same institution" do
    user = users(:southwest_admin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = InviteePolicy.new(context, @element)
    assert policy.create?
  end

  test "create?() does not authorize administrators of a different
  institution" do
    user    = users(:southwest_admin)
    context = RequestContext.new(user:        user,
                                 institution: institutions(:northeast))
    policy  = InviteePolicy.new(context, @element)
    assert !policy.create?
  end

  test "create?() respects role limits" do
    # sysadmin user limited to an insufficient role
    user    = users(:local_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::LOGGED_IN)
    policy  = InviteePolicy.new(context, @item)
    assert !policy.create?
  end

  # create_unsolicited?()

  test "create_unsolicited?() returns true with a nil user" do
    policy = InviteePolicy.new(nil, @invitee)
    assert policy.create_unsolicited?
  end

  test "create_unsolicited?() does not authorize logged-in users" do
    user    = users(:norights)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = InviteePolicy.new(context, @invitee)
    assert !policy.create_unsolicited?
  end

  test "create_unsolicited?() authorizes non-logged-in users" do
    context = RequestContext.new(user:        nil,
                                 institution: institutions(:uiuc))
    policy  = InviteePolicy.new(context, @invitee)
    assert policy.create_unsolicited?
  end

  # destroy?()

  test "destroy?() returns false with a nil user" do
    policy = InviteePolicy.new(nil, @invitee)
    assert !policy.destroy?
  end

  test "destroy?() does not authorize non-sysadmins" do
    user    = users(:norights)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = InviteePolicy.new(context, @invitee)
    assert !policy.destroy?
  end

  test "destroy?() authorizes sysadmins" do
    user    = users(:local_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = InviteePolicy.new(context, @invitee)
    assert policy.destroy?
  end

  test "destroy?() authorizes administrators of the same institution" do
    user = users(:southwest_admin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = InviteePolicy.new(context, @element)
    assert policy.destroy?
  end

  test "destroy?() does not authorize administrators of a different
  institution" do
    user    = users(:southwest_admin)
    context = RequestContext.new(user:        user,
                                 institution: institutions(:northeast))
    policy  = InviteePolicy.new(context, @element)
    assert !policy.destroy?
  end

  test "destroy?() respects role limits" do
    # sysadmin user limited to an insufficient role
    user    = users(:local_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::LOGGED_IN)
    policy  = InviteePolicy.new(context, @item)
    assert !policy.destroy?
  end

  # index?()

  test "index?() returns false with a nil user" do
    policy = InviteePolicy.new(nil, @invitee)
    assert !policy.index?
  end

  test "index?() does not authorize non-sysadmins" do
    user    = users(:norights)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy = InviteePolicy.new(context, @invitee)
    assert !policy.index?
  end

  test "index?() authorizes sysadmins" do
    user    = users(:local_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy = InviteePolicy.new(context, @invitee)
    assert policy.index?
  end

  test "index?() authorizes administrators of the same institution" do
    user = users(:southwest_admin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = InviteePolicy.new(context, @element)
    assert policy.index?
  end

  test "index?() does not authorize administrators of a different
  institution" do
    user    = users(:southwest_admin)
    context = RequestContext.new(user:        user,
                                 institution: institutions(:northeast))
    policy  = InviteePolicy.new(context, @element)
    assert !policy.index?
  end

  test "index?() respects role limits" do
    # sysadmin user limited to an insufficient role
    user    = users(:local_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::LOGGED_IN)
    policy  = InviteePolicy.new(context, @item)
    assert !policy.index?
  end

  # new?()

  test "new?() returns true with a nil user" do
    policy = InviteePolicy.new(nil, @invitee)
    assert policy.new?
  end

  test "new?() does not authorize logged-in users" do
    user    = users(:norights)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = InviteePolicy.new(context, @invitee)
    assert !policy.new?
  end

  test "new?() authorizes non-logged-in users" do
    context = RequestContext.new(user:        nil,
                                 institution: institutions(:uiuc))
    policy  = InviteePolicy.new(context, @invitee)
    assert policy.new?
  end

  # reject?()

  test "reject?() returns false with a nil user" do
    policy = InviteePolicy.new(nil, @invitee)
    assert !policy.reject?
  end

  test "reject?() does not authorize non-sysadmins" do
    user    = users(:norights)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = InviteePolicy.new(context, @invitee)
    assert !policy.reject?
  end

  test "reject?() authorizes sysadmins" do
    user    = users(:local_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = InviteePolicy.new(context, @invitee)
    assert policy.reject?
  end

  test "reject?() authorizes administrators of the same institution" do
    user = users(:southwest_admin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = InviteePolicy.new(context, @element)
    assert policy.reject?
  end

  test "reject?() does not authorize administrators of a different
  institution" do
    user    = users(:southwest_admin)
    context = RequestContext.new(user:        user,
                                 institution: institutions(:northeast))
    policy  = InviteePolicy.new(context, @element)
    assert !policy.reject?
  end

  test "reject?() respects role limits" do
    # sysadmin user limited to an insufficient role
    user    = users(:local_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::LOGGED_IN)
    policy  = InviteePolicy.new(context, @item)
    assert !policy.reject?
  end

  # resend_email?()

  test "resend_email?() returns false with a nil user" do
    policy = InviteePolicy.new(nil, @invitee)
    assert !policy.resend_email?
  end

  test "resend_email?() does not authorize non-sysadmins" do
    user    = users(:norights)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = InviteePolicy.new(context, @invitee)
    assert !policy.resend_email?
  end

  test "resend_email?() authorizes sysadmins" do
    user    = users(:local_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = InviteePolicy.new(context, @invitee)
    assert policy.resend_email?
  end

  test "resend_email?() authorizes administrators of the same institution" do
    user = users(:southwest_admin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = InviteePolicy.new(context, @element)
    assert policy.resend_email?
  end

  test "resend_email?() does not authorize administrators of a different
  institution" do
    user    = users(:southwest_admin)
    context = RequestContext.new(user:        user,
                                 institution: institutions(:northeast))
    policy  = InviteePolicy.new(context, @element)
    assert !policy.resend_email?
  end

  test "resend_email?() respects role limits" do
    # sysadmin user limited to an insufficient role
    user    = users(:local_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::LOGGED_IN)
    policy  = InviteePolicy.new(context, @item)
    assert !policy.resend_email?
  end

  # show?()

  test "show?() returns false with a nil user" do
    policy = InviteePolicy.new(nil, @invitee)
    assert !policy.show?
  end

  test "show?() does not authorize non-sysadmins" do
    user    = users(:norights)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy = InviteePolicy.new(context, @invitee)
    assert !policy.show?
  end

  test "show?() authorizes sysadmins" do
    user    = users(:local_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy = InviteePolicy.new(context, @invitee)
    assert policy.show?
  end

  test "show?() authorizes administrators of the same institution" do
    user = users(:southwest_admin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = InviteePolicy.new(context, @element)
    assert policy.show?
  end

  test "show?() does not authorize administrators of a different
  institution" do
    user    = users(:southwest_admin)
    context = RequestContext.new(user:        user,
                                 institution: institutions(:northeast))
    policy  = InviteePolicy.new(context, @element)
    assert !policy.show?
  end

  test "show?() respects role limits" do
    # sysadmin user limited to an insufficient role
    user    = users(:local_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::LOGGED_IN)
    policy  = InviteePolicy.new(context, @item)
    assert !policy.show?
  end

end
