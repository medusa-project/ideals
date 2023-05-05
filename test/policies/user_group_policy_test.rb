require 'test_helper'

class UserGroupPolicyTest < ActiveSupport::TestCase

  setup do
    @user_group = user_groups(:southwest_unused)
  end

  # create?()

  test "create?() returns false with a nil user" do
    context = RequestContext.new(user:        nil,
                                 institution: @user_group.institution)
    policy = UserGroupPolicy.new(context, @user_group)
    assert !policy.create?
  end

  test "create?() authorizes administrators of any institution" do
    subject_user = users(:southwest)
    subject_user.institution_administrators.build(institution: subject_user.institution)
    subject_user.save!
    context      = RequestContext.new(user:        subject_user,
                                      institution: subject_user.institution)
    policy       = UserGroupPolicy.new(context, @user_group)
    assert policy.create?
  end

  test "create?() authorizes sysadmins" do
    user    = users(:southwest_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = UserGroupPolicy.new(context, @user_group)
    assert policy.create?
  end

  test "create?() does not authorize anybody else" do
    user    = users(:southwest)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = UserGroupPolicy.new(context, @user_group)
    assert !policy.create?
  end

  test "create?() respects role limits" do
    # sysadmin user limited to an insufficient role
    user    = users(:southwest_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::LOGGED_IN)
    policy  = UserGroupPolicy.new(context, @user_group)
    assert !policy.create?
  end

  # destroy?()

  test "destroy?() returns false with a nil user" do
    context = RequestContext.new(user:        nil,
                                 institution: @user_group.institution)
    policy = UserGroupPolicy.new(context, @user_group)
    assert !policy.destroy?
  end

  test "destroy?() does not authorize an incorrect scope" do
    context = RequestContext.new(user:        users(:southwest_admin),
                                 institution: institutions(:northeast))
    policy  = UserGroupPolicy.new(context, @user_group)
    assert !policy.destroy?
  end

  test "destroy?() authorizes sysadmins" do
    user    = users(:southwest_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = UserGroupPolicy.new(context, @user_group)
    assert policy.destroy?
  end

  test "destroy?() authorizes administrators of the same institution as the
  user group" do
    user    = users(:southwest_admin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = UserGroupPolicy.new(context, @user_group)
    assert policy.destroy?
  end

  test "destroy?() does not authorize administrators of a different institution
  than that of the user group" do
    user    = users(:northeast_admin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = UserGroupPolicy.new(context, @user_group)
    assert !policy.destroy?
  end

  test "destroy?() does not authorize anybody else" do
    user    = users(:southwest)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = UserGroupPolicy.new(context, @user_group)
    assert !policy.destroy?
  end

  test "destroy?() respects role limits" do
    # sysadmin user limited to an insufficient role
    user    = users(:southwest_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::LOGGED_IN)
    policy  = UserGroupPolicy.new(context, @user_group)
    assert !policy.destroy?
  end

  test "destroy?() does not authorize system-required groups" do
    user    = users(:southwest_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = UserGroupPolicy.new(context, @user_group)
    assert policy.destroy?
  end

  # edit?()

  test "edit?() returns false with a nil user" do
    context = RequestContext.new(user:        nil,
                                 institution: @user_group.institution)
    policy = UserGroupPolicy.new(context, @user_group)
    assert !policy.edit?
  end

  test "edit?() does not authorize an incorrect scope" do
    context = RequestContext.new(user:        users(:southwest_admin),
                                 institution: institutions(:northeast))
    policy  = UserGroupPolicy.new(context, @user_group)
    assert !policy.edit?
  end

  test "edit?() authorizes sysadmins" do
    user    = users(:southwest_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy = UserGroupPolicy.new(context, @user_group)
    assert policy.edit?
  end

  test "edit?() authorizes administrators of the same institution as the
  user group" do
    user    = users(:southwest_admin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = UserGroupPolicy.new(context, @user_group)
    assert policy.edit?
  end

  test "edit?() does not authorize administrators of a different institution
  than that of the user group" do
    user    = users(:northeast_admin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = UserGroupPolicy.new(context, @user_group)
    assert !policy.edit?
  end

  test "edit?() does not authorize anybody else" do
    user    = users(:southwest)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = UserGroupPolicy.new(context, @user_group)
    assert !policy.edit?
  end

  test "edit?() respects role limits" do
    # sysadmin user limited to an insufficient role
    user    = users(:southwest_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::LOGGED_IN)
    policy  = UserGroupPolicy.new(context, @user_group)
    assert !policy.edit?
  end

  # edit_ad_groups?()

  test "edit_ad_groups?() returns false with a nil user" do
    context = RequestContext.new(user:        nil,
                                 institution: @user_group.institution)
    policy = UserGroupPolicy.new(context, @user_group)
    assert !policy.edit_ad_groups?
  end

  test "edit_ad_groups?() does not authorize an incorrect scope" do
    context = RequestContext.new(user:        users(:southwest_admin),
                                 institution: institutions(:northeast))
    policy  = UserGroupPolicy.new(context, @user_group)
    assert !policy.edit_ad_groups?
  end

  test "edit_ad_groups?() authorizes sysadmins" do
    user    = users(:southwest_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy = UserGroupPolicy.new(context, @user_group)
    assert policy.edit_ad_groups?
  end

  test "edit_ad_groups?() authorizes administrators of the same institution as the
  user group" do
    user    = users(:southwest_admin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = UserGroupPolicy.new(context, @user_group)
    assert policy.edit_ad_groups?
  end

  test "edit_ad_groups?() does not authorize administrators of a different institution
  than that of the user group" do
    user    = users(:northeast_admin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = UserGroupPolicy.new(context, @user_group)
    assert !policy.edit_ad_groups?
  end

  test "edit_ad_groups?() does not authorize anybody else" do
    user    = users(:southwest)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = UserGroupPolicy.new(context, @user_group)
    assert !policy.edit_ad_groups?
  end

  test "edit_ad_groups?() respects role limits" do
    # sysadmin user limited to an insufficient role
    user    = users(:southwest_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::LOGGED_IN)
    policy  = UserGroupPolicy.new(context, @user_group)
    assert !policy.edit_ad_groups?
  end

  # edit_affiliations?()

  test "edit_affiliations?() returns false with a nil user" do
    context = RequestContext.new(user:        nil,
                                 institution: @user_group.institution)
    policy = UserGroupPolicy.new(context, @user_group)
    assert !policy.edit_affiliations?
  end

  test "edit_affiliations?() does not authorize an incorrect scope" do
    context = RequestContext.new(user:        users(:southwest_admin),
                                 institution: institutions(:northeast))
    policy  = UserGroupPolicy.new(context, @user_group)
    assert !policy.edit_affiliations?
  end

  test "edit_affiliations?() authorizes sysadmins" do
    user    = users(:southwest_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy = UserGroupPolicy.new(context, @user_group)
    assert policy.edit_affiliations?
  end

  test "edit_affiliations?() authorizes administrators of the same institution as the
  user group" do
    user    = users(:southwest_admin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = UserGroupPolicy.new(context, @user_group)
    assert policy.edit_affiliations?
  end

  test "edit_affiliations?() does not authorize administrators of a different institution
  than that of the user group" do
    user    = users(:northeast_admin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = UserGroupPolicy.new(context, @user_group)
    assert !policy.edit_affiliations?
  end

  test "edit_affiliations?() does not authorize anybody else" do
    user    = users(:southwest)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = UserGroupPolicy.new(context, @user_group)
    assert !policy.edit_affiliations?
  end

  test "edit_affiliations?() respects role limits" do
    # sysadmin user limited to an insufficient role
    user    = users(:southwest_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::LOGGED_IN)
    policy  = UserGroupPolicy.new(context, @user_group)
    assert !policy.edit_affiliations?
  end

  # edit_departments?()

  test "edit_departments?() returns false with a nil user" do
    context = RequestContext.new(user:        nil,
                                 institution: @user_group.institution)
    policy = UserGroupPolicy.new(context, @user_group)
    assert !policy.edit_departments?
  end

  test "edit_departments?() does not authorize an incorrect scope" do
    context = RequestContext.new(user:        users(:southwest_admin),
                                 institution: institutions(:northeast))
    policy  = UserGroupPolicy.new(context, @user_group)
    assert !policy.edit_departments?
  end

  test "edit_departments?() authorizes sysadmins" do
    user    = users(:southwest_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy = UserGroupPolicy.new(context, @user_group)
    assert policy.edit_departments?
  end

  test "edit_departments?() authorizes administrators of the same institution
  as the user group" do
    user    = users(:southwest_admin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = UserGroupPolicy.new(context, @user_group)
    assert policy.edit_departments?
  end

  test "edit_departments?() does not authorize administrators of a different
  institution than that of the user group" do
    user    = users(:northeast_admin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = UserGroupPolicy.new(context, @user_group)
    assert !policy.edit_departments?
  end

  test "edit_departments?() does not authorize anybody else" do
    user    = users(:southwest)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = UserGroupPolicy.new(context, @user_group)
    assert !policy.edit_departments?
  end

  test "edit_departments?() respects role limits" do
    # sysadmin user limited to an insufficient role
    user    = users(:southwest_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::LOGGED_IN)
    policy  = UserGroupPolicy.new(context, @user_group)
    assert !policy.edit_departments?
  end

  # edit_email_patterns?()

  test "edit_email_patterns?() returns false with a nil user" do
    context = RequestContext.new(user:        nil,
                                 institution: @user_group.institution)
    policy = UserGroupPolicy.new(context, @user_group)
    assert !policy.edit_email_patterns?
  end

  test "edit_email_patterns?() does not authorize an incorrect scope" do
    context = RequestContext.new(user:        users(:southwest_admin),
                                 institution: institutions(:northeast))
    policy  = UserGroupPolicy.new(context, @user_group)
    assert !policy.edit_email_patterns?
  end

  test "edit_email_patterns?() authorizes sysadmins" do
    user    = users(:southwest_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy = UserGroupPolicy.new(context, @user_group)
    assert policy.edit_email_patterns?
  end

  test "edit_email_patterns?() authorizes administrators of the same institution as the
  user group" do
    user    = users(:southwest_admin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = UserGroupPolicy.new(context, @user_group)
    assert policy.edit_email_patterns?
  end

  test "edit_email_patterns?() does not authorize administrators of a different institution
  than that of the user group" do
    user    = users(:northeast_admin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = UserGroupPolicy.new(context, @user_group)
    assert !policy.edit_email_patterns?
  end

  test "edit_email_patterns?() does not authorize anybody else" do
    user    = users(:southwest)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = UserGroupPolicy.new(context, @user_group)
    assert !policy.edit_email_patterns?
  end

  test "edit_email_patterns?() respects role limits" do
    # sysadmin user limited to an insufficient role
    user    = users(:southwest_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::LOGGED_IN)
    policy  = UserGroupPolicy.new(context, @user_group)
    assert !policy.edit_email_patterns?
  end

  # edit_hosts?()

  test "edit_hosts?() returns false with a nil user" do
    context = RequestContext.new(user:        nil,
                                 institution: @user_group.institution)
    policy = UserGroupPolicy.new(context, @user_group)
    assert !policy.edit_hosts?
  end

  test "edit_hosts?() does not authorize an incorrect scope" do
    context = RequestContext.new(user:        users(:southwest_admin),
                                 institution: institutions(:northeast))
    policy  = UserGroupPolicy.new(context, @user_group)
    assert !policy.edit_hosts?
  end

  test "edit_hosts?() authorizes sysadmins" do
    user    = users(:southwest_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy = UserGroupPolicy.new(context, @user_group)
    assert policy.edit_hosts?
  end

  test "edit_hosts?() authorizes administrators of the same institution as the
  user group" do
    user    = users(:southwest_admin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = UserGroupPolicy.new(context, @user_group)
    assert policy.edit_hosts?
  end

  test "edit_hosts?() does not authorize administrators of a different
  institution than that of the user group" do
    user    = users(:northeast_admin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = UserGroupPolicy.new(context, @user_group)
    assert !policy.edit_hosts?
  end

  test "edit_hosts?() does not authorize anybody else" do
    user    = users(:southwest)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = UserGroupPolicy.new(context, @user_group)
    assert !policy.edit_hosts?
  end

  test "edit_hosts?() respects role limits" do
    # sysadmin user limited to an insufficient role
    user    = users(:southwest_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::LOGGED_IN)
    policy  = UserGroupPolicy.new(context, @user_group)
    assert !policy.edit_hosts?
  end

  # edit_users?()

  test "edit_users?() returns false with a nil user" do
    context = RequestContext.new(user:        nil,
                                 institution: @user_group.institution)
    policy = UserGroupPolicy.new(context, @user_group)
    assert !policy.edit_users?
  end

  test "edit_users?() does not authorize an incorrect scope" do
    context = RequestContext.new(user:        users(:southwest_admin),
                                 institution: institutions(:northeast))
    policy  = UserGroupPolicy.new(context, @user_group)
    assert !policy.edit_users?
  end

  test "edit_users?() authorizes sysadmins" do
    user    = users(:southwest_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy = UserGroupPolicy.new(context, @user_group)
    assert policy.edit_users?
  end

  test "edit_users?() authorizes administrators of the same institution
  as the user group" do
    user    = users(:southwest_admin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = UserGroupPolicy.new(context, @user_group)
    assert policy.edit_users?
  end

  test "edit_users?() does not authorize administrators of a different
  institution than that of the user group" do
    user    = users(:northeast_admin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = UserGroupPolicy.new(context, @user_group)
    assert !policy.edit_users?
  end

  test "edit_users?() does not authorize anybody else" do
    user    = users(:southwest)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = UserGroupPolicy.new(context, @user_group)
    assert !policy.edit_users?
  end

  test "edit_users?() respects role limits" do
    # sysadmin user limited to an insufficient role
    user    = users(:southwest_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::LOGGED_IN)
    policy  = UserGroupPolicy.new(context, @user_group)
    assert !policy.edit_users?
  end

  # index?()

  test "index?() returns false with a nil user" do
    context = RequestContext.new(user:        nil,
                                 institution: @user_group.institution)
    policy = UserGroupPolicy.new(context, UserGroup)
    assert !policy.index?
  end

  test "index?() authorizes sysadmins" do
    user    = users(:southwest_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy = UserGroupPolicy.new(context, UserGroup)
    assert policy.index?
  end

  test "index?() does not authorize anybody else" do
    user    = users(:southwest)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = UserGroupPolicy.new(context, UserGroup)
    assert !policy.index?
  end

  test "index?() respects role limits" do
    # sysadmin user limited to an insufficient role
    user    = users(:southwest_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::LOGGED_IN)
    policy  = UserGroupPolicy.new(context, @user_group)
    assert !policy.index?
  end

  # index_global?()

  test "index_global?() returns false with a nil user" do
    context = RequestContext.new(user:        nil,
                                 institution: @user_group.institution)
    policy = UserGroupPolicy.new(context, @user_group)
    assert !policy.index_global?
  end

  test "index_global?() does not authorize non-sysadmins" do
    user    = users(:southwest)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy = UserGroupPolicy.new(context, @user_group)
    assert !policy.index_global?
  end

  test "index_global?() authorizes sysadmins" do
    user    = users(:southwest_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = UserGroupPolicy.new(context, @user_group)
    assert policy.index_global?
  end

  test "index_global?() respects role limits" do
    # sysadmin user limited to an insufficient role
    user    = users(:southwest_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::LOGGED_IN)
    policy  = UserGroupPolicy.new(context, @user_group)
    assert !policy.index_global?
  end

  # new()

  test "new?() returns false with a nil user" do
    context = RequestContext.new(user:        nil,
                                 institution: @user_group.institution)
    policy = UserGroupPolicy.new(context, @user_group)
    assert !policy.new?
  end

  test "new?() authorizes sysadmins" do
    user    = users(:southwest_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = UserGroupPolicy.new(context, @user_group)
    assert policy.new?
  end

  test "new?() does not authorize anybody else" do
    user    = users(:southwest)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = UserGroupPolicy.new(context, @user_group)
    assert !policy.new?
  end

  test "new?() respects role limits" do
    # sysadmin user limited to an insufficient role
    user    = users(:southwest_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::LOGGED_IN)
    policy  = UserGroupPolicy.new(context, @user_group)
    assert !policy.new?
  end

  # show?()

  test "show?() returns false with a nil user" do
    context = RequestContext.new(user:        nil,
                                 institution: @user_group.institution)
    policy = UserGroupPolicy.new(context, @user_group)
    assert !policy.show?
  end

  test "show?() authorizes sysadmins" do
    user    = users(:southwest_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy = UserGroupPolicy.new(context, @user_group)
    assert policy.show?
  end

  test "show?() authorizes administrators of the same institution as the user
  group" do
    user    = users(:southwest_admin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = UserGroupPolicy.new(context, @user_group)
    assert policy.show?
  end

  test "show?() does not authorize administrators of a different institution
  than that of the user group" do
    user    = users(:northeast_admin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = UserGroupPolicy.new(context, @user_group)
    assert !policy.show?
  end

  test "show?() does not authorize anybody else" do
    user    = users(:southwest)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = UserGroupPolicy.new(context, @user_group)
    assert !policy.show?
  end

  test "show?() respects role limits" do
    # sysadmin user limited to an insufficient role
    user    = users(:southwest_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::LOGGED_IN)
    policy  = UserGroupPolicy.new(context, @user_group)
    assert !policy.show?
  end

  # update?()

  test "update?() returns false with a nil user" do
    context = RequestContext.new(user:        nil,
                                 institution: @user_group.institution)
    policy = UserGroupPolicy.new(context, @user_group)
    assert !policy.update?
  end

  test "update?() does not authorize an incorrect scope" do
    context = RequestContext.new(user:        users(:southwest_admin),
                                 institution: institutions(:northeast))
    policy  = UserGroupPolicy.new(context, @user_group)
    assert !policy.update?
  end

  test "update?() authorizes sysadmins" do
    user    = users(:southwest_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy = UserGroupPolicy.new(context, @user_group)
    assert policy.update?
  end

  test "update?() authorizes administrators of the same institution as the
  user group" do
    user    = users(:southwest_admin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = UserGroupPolicy.new(context, @user_group)
    assert policy.update?
  end

  test "update?() does not authorize administrators of a different institution
  than that of the user group" do
    user    = users(:northeast_admin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = UserGroupPolicy.new(context, @user_group)
    assert !policy.update?
  end

  test "update?() does not authorize anybody else" do
    user    = users(:southwest)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy = UserGroupPolicy.new(context, @user_group)
    assert !policy.update?
  end

  test "update?() respects role limits" do
    # sysadmin user limited to an insufficient role
    user    = users(:southwest_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::LOGGED_IN)
    policy  = UserGroupPolicy.new(context, @user_group)
    assert !policy.update?
  end

end
