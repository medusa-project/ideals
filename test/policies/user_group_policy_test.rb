require 'test_helper'

class UserGroupPolicyTest < ActiveSupport::TestCase

  setup do
    @user_group = user_groups(:unused)
  end

  # create?()

  test "create?() returns false with a nil user" do
    policy = UserGroupPolicy.new(nil, @user_group)
    assert !policy.create?
  end

  test "create?() authorizes managers of any collection" do
    subject_user = users(:norights)
    subject_user.managers.build(collection: collections(:uiuc_collection1))
    subject_user.save!
    context = RequestContext.new(user:        subject_user,
                                 institution: subject_user.institution)
    policy  = UserGroupPolicy.new(context, @user_group)
    assert policy.create?
  end

  test "create?() authorizes administrators of any unit" do
    subject_user = users(:norights)
    subject_user.unit_administrators.build(unit: units(:unit1))
    subject_user.save!
    subject_user = users(:norights)
    context      = RequestContext.new(user:        subject_user,
                                      institution: subject_user.institution)
    policy       = UserGroupPolicy.new(context, @user_group)
    assert policy.create?
  end

  test "create?() authorizes administrators of any institution" do
    subject_user = users(:norights)
    subject_user.institution_administrators.build(institution: subject_user.institution)
    subject_user.save!
    subject_user = users(:norights)
    context      = RequestContext.new(user:        subject_user,
                                      institution: subject_user.institution)
    policy       = UserGroupPolicy.new(context, @user_group)
    assert policy.create?
  end

  test "create?() authorizes sysadmins" do
    user    = users(:local_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = UserGroupPolicy.new(context, @user_group)
    assert policy.create?
  end

  test "create?() does not authorize anybody else" do
    user    = users(:norights)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = UserGroupPolicy.new(context, @user_group)
    assert !policy.create?
  end

  test "create?() respects role limits" do
    # sysadmin user limited to an insufficient role
    user    = users(:local_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::LOGGED_IN)
    policy  = UserGroupPolicy.new(context, @user_group)
    assert !policy.create?
  end

  # destroy?()

  test "destroy?() returns false with a nil user" do
    policy = UserGroupPolicy.new(nil, @user_group)
    assert !policy.destroy?
  end

  test "destroy?() authorizes managers of any collection" do
    subject_user = users(:norights)
    subject_user.managers.build(collection: collections(:uiuc_collection1))
    subject_user.save!
    context = RequestContext.new(user:        subject_user,
                                 institution: subject_user.institution)
    policy  = UserGroupPolicy.new(context, @user_group)
    assert policy.destroy?
  end

  test "destroy?() authorizes administrators of any unit" do
    subject_user = users(:norights)
    subject_user.unit_administrators.build(unit: units(:unit1))
    subject_user.save!
    context = RequestContext.new(user:        subject_user,
                                 institution: subject_user.institution)
    policy  = UserGroupPolicy.new(context, @user_group)
    assert policy.destroy?
  end

  test "destroy?() authorizes sysadmins" do
    user    = users(:local_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = UserGroupPolicy.new(context, @user_group)
    assert policy.destroy?
  end

  test "destroy?() does not authorize anybody else" do
    user    = users(:norights)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = UserGroupPolicy.new(context, @user_group)
    assert !policy.destroy?
  end

  test "destroy?() respects role limits" do
    # sysadmin user limited to an insufficient role
    user    = users(:local_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::LOGGED_IN)
    policy  = UserGroupPolicy.new(context, @user_group)
    assert !policy.destroy?
  end

  test "destroy?() does not authorize system-required groups" do
    user    = users(:local_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = UserGroupPolicy.new(context, @user_group)
    assert policy.destroy?
  end

  # edit?()

  test "edit?() returns false with a nil user" do
    policy = UserGroupPolicy.new(nil, @user_group)
    assert !policy.edit?
  end

  test "edit?() authorizes managers of any collection" do
    subject_user = users(:norights)
    subject_user.managers.build(collection: collections(:uiuc_collection1))
    subject_user.save!
    context = RequestContext.new(user:        subject_user,
                                 institution: subject_user.institution)
    policy  = UserGroupPolicy.new(context, @user_group)
    assert policy.edit?
  end

  test "edit?() authorizes administrators of any unit" do
    subject_user = users(:norights)
    subject_user.unit_administrators.build(unit: units(:unit1))
    subject_user.save!
    context = RequestContext.new(user:        subject_user,
                                 institution: subject_user.institution)
    policy  = UserGroupPolicy.new(context, @user_group)
    assert policy.edit?
  end

  test "edit?() authorizes sysadmins" do
    user    = users(:local_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy = UserGroupPolicy.new(context, @user_group)
    assert policy.edit?
  end

  test "edit?() does not authorize anybody else" do
    user    = users(:norights)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = UserGroupPolicy.new(context, @user_group)
    assert !policy.edit?
  end

  test "edit?() respects role limits" do
    # sysadmin user limited to an insufficient role
    user    = users(:local_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::LOGGED_IN)
    policy  = UserGroupPolicy.new(context, @user_group)
    assert !policy.edit?
  end

  # edit_ad_groups?()

  test "edit_ad_groups?() returns false with a nil user" do
    policy = UserGroupPolicy.new(nil, @user_group)
    assert !policy.edit_ad_groups?
  end

  test "edit_ad_groups?() authorizes managers of any collection" do
    subject_user = users(:norights)
    subject_user.managers.build(collection: collections(:uiuc_collection1))
    subject_user.save!
    context = RequestContext.new(user:        subject_user,
                                 institution: subject_user.institution)
    policy  = UserGroupPolicy.new(context, @user_group)
    assert policy.edit_ad_groups?
  end

  test "edit_ad_groups?() authorizes administrators of any unit" do
    subject_user = users(:norights)
    subject_user.unit_administrators.build(unit: units(:unit1))
    subject_user.save!
    context = RequestContext.new(user:        subject_user,
                                 institution: subject_user.institution)
    policy  = UserGroupPolicy.new(context, @user_group)
    assert policy.edit_ad_groups?
  end

  test "edit_ad_groups?() authorizes sysadmins" do
    user    = users(:local_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy = UserGroupPolicy.new(context, @user_group)
    assert policy.edit_ad_groups?
  end

  test "edit_ad_groups?() does not authorize anybody else" do
    user    = users(:norights)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = UserGroupPolicy.new(context, @user_group)
    assert !policy.edit_ad_groups?
  end

  test "edit_ad_groups?() respects role limits" do
    # sysadmin user limited to an insufficient role
    user    = users(:local_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::LOGGED_IN)
    policy  = UserGroupPolicy.new(context, @user_group)
    assert !policy.edit_ad_groups?
  end

  # edit_affiliations?()

  test "edit_affiliations?() returns false with a nil user" do
    policy = UserGroupPolicy.new(nil, @user_group)
    assert !policy.edit_affiliations?
  end

  test "edit_affiliations?() authorizes managers of any collection" do
    subject_user = users(:norights)
    subject_user.managers.build(collection: collections(:uiuc_collection1))
    subject_user.save!
    context = RequestContext.new(user:        subject_user,
                                 institution: subject_user.institution)
    policy  = UserGroupPolicy.new(context, @user_group)
    assert policy.edit_affiliations?
  end

  test "edit_affiliations?() authorizes administrators of any unit" do
    subject_user = users(:norights)
    subject_user.unit_administrators.build(unit: units(:unit1))
    subject_user.save!
    context = RequestContext.new(user:        subject_user,
                                 institution: subject_user.institution)
    policy  = UserGroupPolicy.new(context, @user_group)
    assert policy.edit_affiliations?
  end

  test "edit_affiliations?() authorizes sysadmins" do
    user    = users(:local_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy = UserGroupPolicy.new(context, @user_group)
    assert policy.edit_affiliations?
  end

  test "edit_affiliations?() does not authorize anybody else" do
    user    = users(:norights)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = UserGroupPolicy.new(context, @user_group)
    assert !policy.edit_affiliations?
  end

  test "edit_affiliations?() respects role limits" do
    # sysadmin user limited to an insufficient role
    user    = users(:local_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::LOGGED_IN)
    policy  = UserGroupPolicy.new(context, @user_group)
    assert !policy.edit_affiliations?
  end

  # edit_departments?()

  test "edit_departments?() returns false with a nil user" do
    policy = UserGroupPolicy.new(nil, @user_group)
    assert !policy.edit_departments?
  end

  test "edit_departments?() authorizes managers of any collection" do
    subject_user = users(:norights)
    subject_user.managers.build(collection: collections(:uiuc_collection1))
    subject_user.save!
    context = RequestContext.new(user:        subject_user,
                                 institution: subject_user.institution)
    policy  = UserGroupPolicy.new(context, @user_group)
    assert policy.edit_departments?
  end

  test "edit_departments?() authorizes administrators of any unit" do
    subject_user = users(:norights)
    subject_user.unit_administrators.build(unit: units(:unit1))
    subject_user.save!
    context = RequestContext.new(user:        subject_user,
                                 institution: subject_user.institution)
    policy  = UserGroupPolicy.new(context, @user_group)
    assert policy.edit_departments?
  end

  test "edit_departments?() authorizes sysadmins" do
    user    = users(:local_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy = UserGroupPolicy.new(context, @user_group)
    assert policy.edit_departments?
  end

  test "edit_departments?() does not authorize anybody else" do
    user    = users(:norights)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = UserGroupPolicy.new(context, @user_group)
    assert !policy.edit_departments?
  end

  test "edit_departments?() respects role limits" do
    # sysadmin user limited to an insufficient role
    user    = users(:local_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::LOGGED_IN)
    policy  = UserGroupPolicy.new(context, @user_group)
    assert !policy.edit_departments?
  end

  # edit_email_patterns?()

  test "edit_email_patterns?() returns false with a nil user" do
    policy = UserGroupPolicy.new(nil, @user_group)
    assert !policy.edit_email_patterns?
  end

  test "edit_email_patterns?() authorizes managers of any collection" do
    subject_user = users(:norights)
    subject_user.managers.build(collection: collections(:uiuc_collection1))
    subject_user.save!
    context = RequestContext.new(user:        subject_user,
                                 institution: subject_user.institution)
    policy  = UserGroupPolicy.new(context, @user_group)
    assert policy.edit_email_patterns?
  end

  test "edit_email_patterns?() authorizes administrators of any unit" do
    subject_user = users(:norights)
    subject_user.unit_administrators.build(unit: units(:unit1))
    subject_user.save!
    context = RequestContext.new(user:        subject_user,
                                 institution: subject_user.institution)
    policy  = UserGroupPolicy.new(context, @user_group)
    assert policy.edit_email_patterns?
  end

  test "edit_email_patterns?() authorizes sysadmins" do
    user    = users(:local_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy = UserGroupPolicy.new(context, @user_group)
    assert policy.edit_email_patterns?
  end

  test "edit_email_patterns?() does not authorize anybody else" do
    user    = users(:norights)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = UserGroupPolicy.new(context, @user_group)
    assert !policy.edit_email_patterns?
  end

  test "edit_email_patterns?() respects role limits" do
    # sysadmin user limited to an insufficient role
    user    = users(:local_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::LOGGED_IN)
    policy  = UserGroupPolicy.new(context, @user_group)
    assert !policy.edit_email_patterns?
  end

  # edit_hosts?()

  test "edit_hosts?() returns false with a nil user" do
    policy = UserGroupPolicy.new(nil, @user_group)
    assert !policy.edit_hosts?
  end

  test "edit_hosts?() authorizes managers of any collection" do
    subject_user = users(:norights)
    subject_user.managers.build(collection: collections(:uiuc_collection1))
    subject_user.save!
    context = RequestContext.new(user:        subject_user,
                                 institution: subject_user.institution)
    policy  = UserGroupPolicy.new(context, @user_group)
    assert policy.edit_hosts?
  end

  test "edit_hosts?() authorizes administrators of any unit" do
    subject_user = users(:norights)
    subject_user.unit_administrators.build(unit: units(:unit1))
    subject_user.save!
    context = RequestContext.new(user:        subject_user,
                                 institution: subject_user.institution)
    policy  = UserGroupPolicy.new(context, @user_group)
    assert policy.edit_hosts?
  end

  test "edit_hosts?() authorizes sysadmins" do
    user    = users(:local_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy = UserGroupPolicy.new(context, @user_group)
    assert policy.edit_hosts?
  end

  test "edit_hosts?() does not authorize anybody else" do
    user    = users(:norights)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = UserGroupPolicy.new(context, @user_group)
    assert !policy.edit_hosts?
  end

  test "edit_hosts?() respects role limits" do
    # sysadmin user limited to an insufficient role
    user    = users(:local_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::LOGGED_IN)
    policy  = UserGroupPolicy.new(context, @user_group)
    assert !policy.edit_hosts?
  end

  # edit_local_users?()

  test "edit_local_users?() returns false with a nil user" do
    policy = UserGroupPolicy.new(nil, @user_group)
    assert !policy.edit_local_users?
  end

  test "edit_local_users?() authorizes managers of any collection" do
    subject_user = users(:norights)
    subject_user.managers.build(collection: collections(:uiuc_collection1))
    subject_user.save!
    context = RequestContext.new(user:        subject_user,
                                 institution: subject_user.institution)
    policy  = UserGroupPolicy.new(context, @user_group)
    assert policy.edit_local_users?
  end

  test "edit_local_users?() authorizes administrators of any unit" do
    subject_user = users(:norights)
    subject_user.unit_administrators.build(unit: units(:unit1))
    subject_user.save!
    context = RequestContext.new(user:        subject_user,
                                 institution: subject_user.institution)
    policy  = UserGroupPolicy.new(context, @user_group)
    assert policy.edit_local_users?
  end

  test "edit_local_users?() authorizes sysadmins" do
    user    = users(:local_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy = UserGroupPolicy.new(context, @user_group)
    assert policy.edit_local_users?
  end

  test "edit_local_users?() does not authorize anybody else" do
    user    = users(:norights)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = UserGroupPolicy.new(context, @user_group)
    assert !policy.edit_local_users?
  end

  test "edit_local_users?() respects role limits" do
    # sysadmin user limited to an insufficient role
    user    = users(:local_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::LOGGED_IN)
    policy  = UserGroupPolicy.new(context, @user_group)
    assert !policy.edit_local_users?
  end

  # edit_netid_users?()

  test "edit_netid_users?() returns false with a nil user" do
    policy = UserGroupPolicy.new(nil, @user_group)
    assert !policy.edit_netid_users?
  end

  test "edit_netid_users?() authorizes managers of any collection" do
    subject_user = users(:norights)
    subject_user.managers.build(collection: collections(:uiuc_collection1))
    subject_user.save!
    context = RequestContext.new(user:        subject_user,
                                 institution: subject_user.institution)
    policy  = UserGroupPolicy.new(context, @user_group)
    assert policy.edit_netid_users?
  end

  test "edit_netid_users?() authorizes administrators of any unit" do
    subject_user = users(:norights)
    subject_user.unit_administrators.build(unit: units(:unit1))
    subject_user.save!
    context = RequestContext.new(user:        subject_user,
                                 institution: subject_user.institution)
    policy  = UserGroupPolicy.new(context, @user_group)
    assert policy.edit_netid_users?
  end

  test "edit_netid_users?() authorizes sysadmins" do
    user    = users(:local_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy = UserGroupPolicy.new(context, @user_group)
    assert policy.edit_netid_users?
  end

  test "edit_netid_users?() does not authorize anybody else" do
    user    = users(:norights)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = UserGroupPolicy.new(context, @user_group)
    assert !policy.edit_netid_users?
  end

  test "edit_netid_users?() respects role limits" do
    # sysadmin user limited to an insufficient role
    user    = users(:local_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::LOGGED_IN)
    policy  = UserGroupPolicy.new(context, @user_group)
    assert !policy.edit_netid_users?
  end

  # index?()

  test "index?() returns false with a nil user" do
    policy = UserGroupPolicy.new(nil, UserGroup)
    assert !policy.index?
  end

  test "index?() authorizes managers of any collection" do
    subject_user = users(:norights)
    subject_user.managers.build(collection: collections(:uiuc_collection1))
    subject_user.save!
    context = RequestContext.new(user:        subject_user,
                                 institution: subject_user.institution)
    policy  = UserGroupPolicy.new(context, UserGroup)
    assert policy.index?
  end

  test "index?() authorizes administrators of any unit" do
    subject_user = users(:norights)
    subject_user.unit_administrators.build(unit: units(:unit1))
    subject_user.save!
    context = RequestContext.new(user:        subject_user,
                                 institution: subject_user.institution)
    policy  = UserGroupPolicy.new(context, UserGroup)
    assert policy.index?
  end

  test "index?() authorizes sysadmins" do
    user    = users(:local_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy = UserGroupPolicy.new(context, UserGroup)
    assert policy.index?
  end

  test "index?() does not authorize anybody else" do
    user    = users(:norights)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = UserGroupPolicy.new(context, UserGroup)
    assert !policy.index?
  end

  test "index?() respects role limits" do
    # sysadmin user limited to an insufficient role
    user    = users(:local_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::LOGGED_IN)
    policy  = UserGroupPolicy.new(context, @user_group)
    assert !policy.index?
  end

  # index_global?()

  test "index_global?() returns false with a nil user" do
    policy = UserGroupPolicy.new(nil, @user_group)
    assert !policy.index_global?
  end

  test "index_global?() does not authorize non-sysadmins" do
    user    = users(:norights)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy = UserGroupPolicy.new(context, @user_group)
    assert !policy.index_global?
  end

  test "index_global?() authorizes sysadmins" do
    user    = users(:local_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = UserGroupPolicy.new(context, @user_group)
    assert policy.index_global?
  end

  test "index_global?() respects role limits" do
    # sysadmin user limited to an insufficient role
    user    = users(:local_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::LOGGED_IN)
    policy  = UserGroupPolicy.new(context, @user_group)
    assert !policy.index_global?
  end

  # new()

  test "new?() returns false with a nil user" do
    policy = UserGroupPolicy.new(nil, @user_group)
    assert !policy.new?
  end

  test "new?() authorizes managers of any collection" do
    subject_user = users(:norights)
    subject_user.managers.build(collection: collections(:uiuc_collection1))
    subject_user.save!
    context = RequestContext.new(user:        subject_user,
                                 institution: subject_user.institution)
    policy  = UserGroupPolicy.new(context, @user_group)
    assert policy.new?
  end

  test "new?() authorizes administrators of any unit" do
    subject_user = users(:norights)
    subject_user.unit_administrators.build(unit: units(:unit1))
    subject_user.save!
    context = RequestContext.new(user:        subject_user,
                                 institution: subject_user.institution)
    policy  = UserGroupPolicy.new(context, @user_group)
    assert policy.new?
  end

  test "new?() authorizes sysadmins" do
    user    = users(:local_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = UserGroupPolicy.new(context, @user_group)
    assert policy.new?
  end

  test "new?() does not authorize anybody else" do
    user    = users(:norights)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = UserGroupPolicy.new(context, @user_group)
    assert !policy.new?
  end

  test "new?() respects role limits" do
    # sysadmin user limited to an insufficient role
    user    = users(:local_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::LOGGED_IN)
    policy  = UserGroupPolicy.new(context, @user_group)
    assert !policy.new?
  end

  # show?()

  test "show?() returns false with a nil user" do
    policy = UserGroupPolicy.new(nil, @user_group)
    assert !policy.show?
  end

  test "show?() authorizes managers of any collection in the same institution" do
    subject_user = users(:norights)
    subject_user.managers.build(collection: collections(:uiuc_collection1))
    subject_user.save!
    @user_group.update!(institution: subject_user.institution)
    context = RequestContext.new(user:        subject_user,
                                 institution: subject_user.institution)
    policy  = UserGroupPolicy.new(context, @user_group)
    assert policy.show?
  end

  test "show?() authorizes administrators of any unit in the same institution" do
    subject_user = users(:norights)
    subject_user.unit_administrators.build(unit: units(:unit1))
    subject_user.save!
    @user_group.update!(institution: subject_user.institution)
    context = RequestContext.new(user:        subject_user,
                                 institution: subject_user.institution)
    policy  = UserGroupPolicy.new(context, @user_group)
    assert policy.show?
  end

  test "show?() authorizes sysadmins" do
    user    = users(:local_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy = UserGroupPolicy.new(context, @user_group)
    assert policy.show?
  end

  test "show?() does not authorize anybody else" do
    user    = users(:norights)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = UserGroupPolicy.new(context, @user_group)
    assert !policy.show?
  end

  test "show?() respects role limits" do
    # sysadmin user limited to an insufficient role
    user    = users(:local_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::LOGGED_IN)
    policy  = UserGroupPolicy.new(context, @user_group)
    assert !policy.show?
  end

  # update?()

  test "update?() returns false with a nil user" do
    policy = UserGroupPolicy.new(nil, @user_group)
    assert !policy.update?
  end

  test "update?() authorizes managers of any collection" do
    subject_user = users(:norights)
    subject_user.managers.build(collection: collections(:uiuc_collection1))
    subject_user.save!
    context = RequestContext.new(user:        subject_user,
                                 institution: subject_user.institution)
    policy  = UserGroupPolicy.new(context, @user_group)
    assert policy.update?
  end

  test "update?() authorizes administrators of any unit" do
    subject_user = users(:norights)
    subject_user.unit_administrators.build(unit: units(:unit1))
    subject_user.save!
    context = RequestContext.new(user:        subject_user,
                                 institution: subject_user.institution)
    policy  = UserGroupPolicy.new(context, @user_group)
    assert policy.update?
  end

  test "update?() authorizes sysadmins" do
    user    = users(:local_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy = UserGroupPolicy.new(context, @user_group)
    assert policy.update?
  end

  test "update?() does not authorize anybody else" do
    user    = users(:norights)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy = UserGroupPolicy.new(context, @user_group)
    assert !policy.update?
  end

  test "update?() respects role limits" do
    # sysadmin user limited to an insufficient role
    user    = users(:local_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::LOGGED_IN)
    policy  = UserGroupPolicy.new(context, @user_group)
    assert !policy.update?
  end

end
