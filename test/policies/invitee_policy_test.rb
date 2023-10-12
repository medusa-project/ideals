require 'test_helper'

class InviteePolicyTest < ActiveSupport::TestCase

  setup do
    @invitee = invitees(:southwest)
  end

  # approve?()

  test "approve?() returns false with a nil user" do
    context = RequestContext.new(user:        nil,
                                 institution: @invitee.institution)
    policy = InviteePolicy.new(context, @invitee)
    assert !policy.approve?
  end

  test "approve?() does not authorize an incorrect scope" do
    context = RequestContext.new(user:        users(:southwest_admin),
                                 institution: institutions(:northeast))
    policy  = InviteePolicy.new(context, @invitee)
    assert !policy.approve?
  end

  test "approve?() does not authorize non-sysadmins" do
    user    = users(:southwest)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = InviteePolicy.new(context, @invitee)
    assert !policy.approve?
  end

  test "approve?() authorizes sysadmins" do
    user    = users(:southwest_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = InviteePolicy.new(context, @invitee)
    assert policy.approve?
  end

  test "approve?() authorizes administrators of the same institution" do
    user = users(:southwest_admin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = InviteePolicy.new(context, @invitee)
    assert policy.approve?
  end

  test "approve?() does not authorize administrators of a different
  institution" do
    user    = users(:southwest_admin)
    context = RequestContext.new(user:        user,
                                 institution: institutions(:northeast))
    policy  = InviteePolicy.new(context, @invitee)
    assert !policy.approve?
  end

  test "approve?() respects role limits" do
    # sysadmin user limited to an insufficient role
    user    = users(:southwest_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::LOGGED_IN)
    policy  = InviteePolicy.new(context, @invitee)
    assert !policy.approve?
  end

  # create?()

  test "create?() returns false with a nil user" do
    context = RequestContext.new(user:        nil,
                                 institution: @invitee.institution)
    policy = InviteePolicy.new(context, @invitee)
    assert !policy.create?
  end

  test "create?() does not authorize an incorrect scope" do
    context = RequestContext.new(user:        users(:southwest_admin),
                                 institution: institutions(:northeast))
    policy  = InviteePolicy.new(context, @invitee)
    assert !policy.create?
  end

  test "create?() does not authorize non-sysadmins" do
    user    = users(:southwest)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = InviteePolicy.new(context, @invitee)
    assert !policy.create?
  end

  test "create?() authorizes sysadmins" do
    user    = users(:southwest_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = InviteePolicy.new(context, @invitee)
    assert policy.create?
  end

  test "create?() authorizes administrators of the same institution" do
    user = users(:southwest_admin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = InviteePolicy.new(context, @invitee)
    assert policy.create?
  end

  test "create?() does not authorize administrators of a different
  institution" do
    user    = users(:southwest_admin)
    context = RequestContext.new(user:        user,
                                 institution: institutions(:northeast))
    policy  = InviteePolicy.new(context, @invitee)
    assert !policy.create?
  end

  test "create?() respects role limits" do
    # sysadmin user limited to an insufficient role
    user    = users(:southwest_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::LOGGED_IN)
    policy  = InviteePolicy.new(context, @invitee)
    assert !policy.create?
  end

  # create_unsolicited?()

  test "create_unsolicited?() returns true with a nil user" do
    context = RequestContext.new(user:        nil,
                                 institution: @invitee.institution)
    policy = InviteePolicy.new(context, @invitee)
    assert policy.create_unsolicited?
  end

  test "create_unsolicited?() does not authorize an incorrect scope" do
    context = RequestContext.new(user:        users(:southwest_admin),
                                 institution: institutions(:northeast))
    policy  = InviteePolicy.new(context, @invitee)
    assert !policy.create_unsolicited?
  end

  test "create_unsolicited?() does not authorize logged-in users" do
    user    = users(:southwest)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = InviteePolicy.new(context, @invitee)
    assert !policy.create_unsolicited?
  end

  test "create_unsolicited?() authorizes non-logged-in users" do
    context = RequestContext.new(user:        nil,
                                 institution: institutions(:southeast))
    policy  = InviteePolicy.new(context, @invitee)
    assert policy.create_unsolicited?
  end

  # destroy?()

  test "destroy?() returns false with a nil user" do
    context = RequestContext.new(user:        nil,
                                 institution: @invitee.institution)
    policy = InviteePolicy.new(context, @invitee)
    assert !policy.destroy?
  end

  test "destroy?() does not authorize an incorrect scope" do
    context = RequestContext.new(user:        users(:southwest_admin),
                                 institution: institutions(:northeast))
    policy  = InviteePolicy.new(context, @invitee)
    assert !policy.destroy?
  end

  test "destroy?() does not authorize non-sysadmins" do
    user    = users(:southwest)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = InviteePolicy.new(context, @invitee)
    assert !policy.destroy?
  end

  test "destroy?() authorizes sysadmins" do
    user    = users(:southwest_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = InviteePolicy.new(context, @invitee)
    assert policy.destroy?
  end

  test "destroy?() authorizes administrators of the same institution" do
    user = users(:southwest_admin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = InviteePolicy.new(context, @invitee)
    assert policy.destroy?
  end

  test "destroy?() does not authorize administrators of a different
  institution" do
    user    = users(:southwest_admin)
    context = RequestContext.new(user:        user,
                                 institution: institutions(:northeast))
    policy  = InviteePolicy.new(context, @invitee)
    assert !policy.destroy?
  end

  test "destroy?() respects role limits" do
    # sysadmin user limited to an insufficient role
    user    = users(:southwest_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::LOGGED_IN)
    policy  = InviteePolicy.new(context, @invitee)
    assert !policy.destroy?
  end

  # edit?()

  test "edit?() returns false with a nil user" do
    context = RequestContext.new(user:        nil,
                                 institution: @invitee.institution)
    policy = InviteePolicy.new(context, @invitee)
    assert !policy.edit?
  end

  test "edit?() does not authorize an incorrect scope" do
    context = RequestContext.new(user:        users(:southwest_admin),
                                 institution: institutions(:northeast))
    policy  = InviteePolicy.new(context, @invitee)
    assert !policy.edit?
  end

  test "edit?() does not authorize non-sysadmins" do
    user    = users(:southwest)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = InviteePolicy.new(context, @invitee)
    assert !policy.edit?
  end

  test "edit?() authorizes sysadmins" do
    user    = users(:southwest_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = InviteePolicy.new(context, @invitee)
    assert policy.edit?
  end

  test "edit?() authorizes administrators of the same institution" do
    user = users(:southwest_admin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = InviteePolicy.new(context, @invitee)
    assert policy.edit?
  end

  test "edit?() does not authorize administrators of a different
  institution" do
    user    = users(:southwest_admin)
    context = RequestContext.new(user:        user,
                                 institution: institutions(:northeast))
    policy  = InviteePolicy.new(context, @invitee)
    assert !policy.edit?
  end

  test "edit?() respects role limits" do
    # sysadmin user limited to an insufficient role
    user    = users(:southwest_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::LOGGED_IN)
    policy  = InviteePolicy.new(context, @invitee)
    assert !policy.edit?
  end

  # index?()

  test "index?() returns false with a nil user" do
    context = RequestContext.new(user:        nil,
                                 institution: @invitee.institution)
    policy = InviteePolicy.new(context, @invitee)
    assert !policy.index?
  end

  test "index?() does not authorize an incorrect scope" do
    context = RequestContext.new(user:        users(:southwest_admin),
                                 institution: institutions(:northeast))
    policy  = InviteePolicy.new(context, @invitee)
    assert !policy.index?
  end

  test "index?() does not authorize non-sysadmins" do
    user    = users(:southwest)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy = InviteePolicy.new(context, @invitee)
    assert !policy.index?
  end

  test "index?() authorizes sysadmins" do
    user    = users(:southwest_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy = InviteePolicy.new(context, @invitee)
    assert policy.index?
  end

  test "index?() authorizes administrators of the same institution" do
    user = users(:southwest_admin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = InviteePolicy.new(context, @invitee)
    assert policy.index?
  end

  test "index?() does not authorize administrators of a different
  institution" do
    user    = users(:southwest_admin)
    context = RequestContext.new(user:        user,
                                 institution: institutions(:northeast))
    policy  = InviteePolicy.new(context, @invitee)
    assert !policy.index?
  end

  test "index?() respects role limits" do
    # sysadmin user limited to an insufficient role
    user    = users(:southwest_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::LOGGED_IN)
    policy  = InviteePolicy.new(context, @invitee)
    assert !policy.index?
  end

  # index_all?()

  test "index_all?() returns false with a nil request context" do
    context = RequestContext.new(user:        nil,
                                 institution: @invitee.institution)
    policy = InviteePolicy.new(context, @institution)
    assert !policy.index_all?
  end

  test "index_all?() does not authorize an incorrect scope" do
    context = RequestContext.new(user:        users(:southwest_admin),
                                 institution: institutions(:northeast))
    policy  = InviteePolicy.new(context, @invitee)
    assert !policy.index_all?
  end

  test "index_all?() is restrictive by default" do
    user    = users(:southwest)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = InviteePolicy.new(context, @institution)
    assert !policy.index_all?
  end

  test "index_all?() authorizes sysadmins" do
    user    = users(:southwest_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = InviteePolicy.new(context, @institution)
    assert policy.index_all?
  end

  test "index_all?() respects role limits" do
    # sysadmin user limited to an insufficient role
    user    = users(:southwest_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::LOGGED_IN)
    policy  = InviteePolicy.new(context, @institution)
    assert !policy.index_all?
  end

  # new?()

  test "new?() returns false with a nil user" do
    context = RequestContext.new(user:        nil,
                                 institution: @invitee.institution)
    policy = InviteePolicy.new(context, @invitee)
    assert !policy.new?
  end

  test "new?() does not authorize an incorrect scope" do
    context = RequestContext.new(user:        users(:southwest_admin),
                                 institution: institutions(:northeast))
    policy  = InviteePolicy.new(context, @invitee)
    assert !policy.new?
  end

  test "new?() does not authorize non-sysadmins" do
    user    = users(:southwest)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = InviteePolicy.new(context, @invitee)
    assert !policy.new?
  end

  test "new?() authorizes sysadmins" do
    user    = users(:southwest_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = InviteePolicy.new(context, @invitee)
    assert policy.new?
  end

  test "new?() authorizes administrators of the same institution" do
    user = users(:southwest_admin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = InviteePolicy.new(context, @invitee)
    assert policy.new?
  end

  test "new?() does not authorize administrators of a different
  institution" do
    user    = users(:southwest_admin)
    context = RequestContext.new(user:        user,
                                 institution: institutions(:northeast))
    policy  = InviteePolicy.new(context, @invitee)
    assert !policy.new?
  end

  test "new?() respects role limits" do
    # sysadmin user limited to an insufficient role
    user    = users(:southwest_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::LOGGED_IN)
    policy  = InviteePolicy.new(context, @invitee)
    assert !policy.new?
  end

  # register?()

  test "register?() returns true with a nil user" do
    context = RequestContext.new(user:        nil,
                                 institution: @invitee.institution)
    policy = InviteePolicy.new(context, @invitee)
    assert policy.register?
  end

  test "register?() does not authorize an incorrect scope" do
    context = RequestContext.new(user:        users(:southwest_admin),
                                 institution: institutions(:northeast))
    policy  = InviteePolicy.new(context, @invitee)
    assert !policy.register?
  end

  test "register?() does not authorize logged-in users" do
    user    = users(:southwest)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = InviteePolicy.new(context, @invitee)
    assert !policy.register?
  end

  test "register?() authorizes non-logged-in users" do
    context = RequestContext.new(user:        nil,
                                 institution: institutions(:southeast))
    policy  = InviteePolicy.new(context, @invitee)
    assert policy.register?
  end

  # reject?()

  test "reject?() returns false with a nil user" do
    context = RequestContext.new(user:        nil,
                                 institution: @invitee.institution)
    policy = InviteePolicy.new(context, @invitee)
    assert !policy.reject?
  end

  test "reject?() does not authorize an incorrect scope" do
    context = RequestContext.new(user:        users(:southwest_admin),
                                 institution: institutions(:northeast))
    policy  = InviteePolicy.new(context, @invitee)
    assert !policy.reject?
  end

  test "reject?() does not authorize non-sysadmins" do
    user    = users(:southwest)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = InviteePolicy.new(context, @invitee)
    assert !policy.reject?
  end

  test "reject?() authorizes sysadmins" do
    user    = users(:southwest_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = InviteePolicy.new(context, @invitee)
    assert policy.reject?
  end

  test "reject?() authorizes administrators of the same institution" do
    user = users(:southwest_admin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = InviteePolicy.new(context, @invitee)
    assert policy.reject?
  end

  test "reject?() does not authorize administrators of a different
  institution" do
    user    = users(:southwest_admin)
    context = RequestContext.new(user:        user,
                                 institution: institutions(:northeast))
    policy  = InviteePolicy.new(context, @invitee)
    assert !policy.reject?
  end

  test "reject?() respects role limits" do
    # sysadmin user limited to an insufficient role
    user    = users(:southwest_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::LOGGED_IN)
    policy  = InviteePolicy.new(context, @invitee)
    assert !policy.reject?
  end

  # resend_email?()

  test "resend_email?() returns false with a nil user" do
    context = RequestContext.new(user:        nil,
                                 institution: @invitee.institution)
    policy = InviteePolicy.new(context, @invitee)
    assert !policy.resend_email?
  end

  test "resend_email?() does not authorize an incorrect scope" do
    context = RequestContext.new(user:        users(:southwest_admin),
                                 institution: institutions(:northeast))
    policy  = InviteePolicy.new(context, @invitee)
    assert !policy.resend_email?
  end

  test "resend_email?() does not authorize non-sysadmins" do
    user    = users(:southwest)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = InviteePolicy.new(context, @invitee)
    assert !policy.resend_email?
  end

  test "resend_email?() authorizes sysadmins" do
    user    = users(:southwest_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = InviteePolicy.new(context, @invitee)
    assert policy.resend_email?
  end

  test "resend_email?() authorizes administrators of the same institution" do
    user = users(:southwest_admin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = InviteePolicy.new(context, @invitee)
    assert policy.resend_email?
  end

  test "resend_email?() does not authorize administrators of a different
  institution" do
    user    = users(:southwest_admin)
    context = RequestContext.new(user:        user,
                                 institution: institutions(:northeast))
    policy  = InviteePolicy.new(context, @invitee)
    assert !policy.resend_email?
  end

  test "resend_email?() respects role limits" do
    # sysadmin user limited to an insufficient role
    user    = users(:southwest_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::LOGGED_IN)
    policy  = InviteePolicy.new(context, @invitee)
    assert !policy.resend_email?
  end

  # show?()

  test "show?() returns false with a nil user" do
    context = RequestContext.new(user:        nil,
                                 institution: @invitee.institution)
    policy = InviteePolicy.new(context, @invitee)
    assert !policy.show?
  end

  test "show?() does not authorize an incorrect scope" do
    context = RequestContext.new(user:        users(:southwest_admin),
                                 institution: institutions(:northeast))
    policy  = InviteePolicy.new(context, @invitee)
    assert !policy.show?
  end

  test "show?() does not authorize non-sysadmins" do
    user    = users(:southwest)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy = InviteePolicy.new(context, @invitee)
    assert !policy.show?
  end

  test "show?() authorizes sysadmins" do
    user    = users(:southwest_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy = InviteePolicy.new(context, @invitee)
    assert policy.show?
  end

  test "show?() authorizes administrators of the same institution" do
    user = users(:southwest_admin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = InviteePolicy.new(context, @invitee)
    assert policy.show?
  end

  test "show?() does not authorize administrators of a different
  institution" do
    user    = users(:southwest_admin)
    context = RequestContext.new(user:        user,
                                 institution: institutions(:northeast))
    policy  = InviteePolicy.new(context, @invitee)
    assert !policy.show?
  end

  test "show?() respects role limits" do
    # sysadmin user limited to an insufficient role
    user    = users(:southwest_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::LOGGED_IN)
    policy  = InviteePolicy.new(context, @invitee)
    assert !policy.show?
  end

end
