require 'test_helper'

class InstitutionPolicyTest < ActiveSupport::TestCase

  setup do
    @institution = institutions(:southwest)
  end

  # create?()

  test "create?() returns false with a nil request context" do
    policy = InstitutionPolicy.new(nil, @institution)
    assert !policy.create?
  end

  test "create?() is restrictive by default" do
    user    = users(:southwest)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = InstitutionPolicy.new(context, @institution)
    assert !policy.create?
  end

  test "create?() authorizes sysadmins" do
    user    = users(:local_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = InstitutionPolicy.new(context, @institution)
    assert policy.create?
  end

  test "create?() respects role limits" do
    # sysadmin user limited to an insufficient role
    user    = users(:southwest_admin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::LOGGED_IN)
    policy  = InstitutionPolicy.new(context, @institution)
    assert !policy.create?
  end

  # destroy?()

  test "destroy?() returns false with a nil request context" do
    policy = InstitutionPolicy.new(nil, @institution)
    assert !policy.destroy?
  end

  test "destroy?() is restrictive by default" do
    user    = users(:southwest)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = InstitutionPolicy.new(context, @institution)
    assert !policy.destroy?
  end

  test "destroy?() authorizes sysadmins" do
    user    = users(:local_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = InstitutionPolicy.new(context, @institution)
    assert policy.destroy?
  end

  test "destroy?() respects role limits" do
    # sysadmin user limited to an insufficient role
    user    = users(:southwest_admin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = InstitutionPolicy.new(context, @institution)
    assert !policy.destroy?
  end

  # edit_administrators?()

  test "edit_administrators?() returns false with a nil user" do
    policy = InstitutionPolicy.new(nil, @institution)
    assert !policy.edit_administrators?
  end

  test "edit_administrators?() is restrictive by default" do
    user    = users(:norights)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = InstitutionPolicy.new(context, @institution)
    assert !policy.edit_administrators?
  end

  test "edit_administrators?() authorizes sysadmins" do
    user    = users(:local_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = InstitutionPolicy.new(context, @institution)
    assert policy.edit_administrators?
  end

  test "edit_administrators?() authorizes administrators of the same
  institution" do
    user    = users(:southwest_admin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = InstitutionPolicy.new(context, user.institution)
    assert policy.edit_administrators?
  end

  test "edit_administrators?() does not authorize administrators of different
  institutions" do
    user    = users(:southwest_admin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = InstitutionPolicy.new(context, @institution)
    assert policy.edit_administrators?
  end

  test "edit_administrators?() respects role limits" do
    # sysadmin user limited to an insufficient role
    user    = users(:local_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::LOGGED_IN)
    policy  = InstitutionPolicy.new(context, @institution)
    assert !policy.edit_administrators?
  end

  # edit_preservation?()

  test "edit_preservation?() returns false with a nil request context" do
    policy = InstitutionPolicy.new(nil, @institution)
    assert !policy.edit_preservation?
  end

  test "edit_preservation?() is restrictive by default" do
    user    = users(:southwest)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = InstitutionPolicy.new(context, @institution)
    assert !policy.edit_preservation?
  end

  test "edit_preservation?() authorizes sysadmins" do
    user    = users(:local_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = InstitutionPolicy.new(context, @institution)
    assert policy.edit_preservation?
  end

  test "edit_preservation?() respects role limits" do
    # sysadmin user limited to an insufficient role
    user    = users(:southwest_admin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::LOGGED_IN)
    policy  = InstitutionPolicy.new(context, @institution)
    assert !policy.edit_preservation?
  end

  # edit_properties?()

  test "edit_properties?() returns false with a nil request context" do
    policy = InstitutionPolicy.new(nil, @institution)
    assert !policy.edit_properties?
  end

  test "edit_properties?() is restrictive by default" do
    user    = users(:southwest)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = InstitutionPolicy.new(context, @institution)
    assert !policy.edit_properties?
  end

  test "edit_properties?() authorizes sysadmins" do
    user    = users(:local_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = InstitutionPolicy.new(context, @institution)
    assert policy.edit_properties?
  end

  test "edit_properties?() respects role limits" do
    # sysadmin user limited to an insufficient role
    user    = users(:southwest_admin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::LOGGED_IN)
    policy  = InstitutionPolicy.new(context, @institution)
    assert !policy.edit_properties?
  end

  # edit_settings?()

  test "edit_settings?() returns false with a nil user" do
    policy = InstitutionPolicy.new(nil, @institution)
    assert !policy.edit_settings?
  end

  test "edit_settings?() is restrictive by default" do
    user    = users(:norights)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = InstitutionPolicy.new(context, @institution)
    assert !policy.edit_settings?
  end

  test "edit_settings?() authorizes sysadmins" do
    user    = users(:local_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = InstitutionPolicy.new(context, @institution)
    assert policy.edit_settings?
  end

  test "edit_settings?() authorizes administrators of the same
  institution" do
    user    = users(:southwest_admin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = InstitutionPolicy.new(context, user.institution)
    assert policy.edit_settings?
  end

  test "edit_settings?() does not authorize administrators of different
  institutions" do
    user    = users(:southwest_admin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = InstitutionPolicy.new(context, @institution)
    assert policy.edit_settings?
  end

  test "edit_settings?() respects role limits" do
    # sysadmin user limited to an insufficient role
    user    = users(:local_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::LOGGED_IN)
    policy  = InstitutionPolicy.new(context, @institution)
    assert !policy.edit_settings?
  end

  # edit_theme?()

  test "edit_theme?() returns false with a nil user" do
    policy = InstitutionPolicy.new(nil, @institution)
    assert !policy.edit_theme?
  end

  test "edit_theme?() is restrictive by default" do
    user    = users(:norights)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = InstitutionPolicy.new(context, @institution)
    assert !policy.edit_theme?
  end

  test "edit_theme?() authorizes sysadmins" do
    user    = users(:local_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = InstitutionPolicy.new(context, @institution)
    assert policy.edit_theme?
  end

  test "edit_theme?() authorizes administrators of the same
  institution" do
    user    = users(:southwest_admin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = InstitutionPolicy.new(context, user.institution)
    assert policy.edit_theme?
  end

  test "edit_theme?() does not authorize administrators of different
  institutions" do
    user    = users(:southwest_admin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = InstitutionPolicy.new(context, @institution)
    assert policy.edit_theme?
  end

  test "edit_theme?() respects role limits" do
    # sysadmin user limited to an insufficient role
    user    = users(:local_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::LOGGED_IN)
    policy  = InstitutionPolicy.new(context, @institution)
    assert !policy.edit_theme?
  end

  # index?()

  test "index?() returns false with a nil request context" do
    policy = InstitutionPolicy.new(nil, @institution)
    assert !policy.index?
  end

  test "index?() is restrictive by default" do
    user    = users(:southwest)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = InstitutionPolicy.new(context, @institution)
    assert !policy.index?
  end

  test "index?() authorizes sysadmins" do
    user    = users(:local_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = InstitutionPolicy.new(context, @institution)
    assert policy.index?
  end

  test "index?() respects role limits" do
    # sysadmin user limited to an insufficient role
    user    = users(:southwest_admin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::LOGGED_IN)
    policy  = InstitutionPolicy.new(context, @institution)
    assert !policy.index?
  end

  # item_download_counts?()

  test "item_download_counts?() returns false with a nil request context" do
    policy = InstitutionPolicy.new(nil, @institution)
    assert !policy.item_download_counts?
  end

  test "item_download_counts?() authorizes sysadmins" do
    user    = users(:local_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = InstitutionPolicy.new(context, @institution)
    assert policy.item_download_counts?
  end

  test "item_download_counts?() authorizes administrators of the same institution" do
    user    = users(:southwest_admin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = InstitutionPolicy.new(context, @institution)
    assert policy.item_download_counts?
  end

  test "item_download_counts?() does not authorize administrators of a different
  institution" do
    user    = users(:southwest_admin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = InstitutionPolicy.new(context, institutions(:uiuc))
    assert !policy.item_download_counts?
  end

  test "item_download_counts?() respects role limits" do
    # sysadmin user limited to an insufficient role
    user    = users(:southwest_admin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::LOGGED_IN)
    policy  = InstitutionPolicy.new(context, @institution)
    assert !policy.item_download_counts?
  end

  # new?()

  test "new?() returns false with a nil request context" do
    policy = InstitutionPolicy.new(nil, @institution)
    assert !policy.new?
  end

  test "new?() is restrictive by default" do
    user    = users(:southwest)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = InstitutionPolicy.new(context, @institution)
    assert !policy.new?
  end

  test "new?() authorizes sysadmins" do
    user    = users(:local_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = InstitutionPolicy.new(context, @institution)
    assert policy.new?
  end

  test "new?() respects role limits" do
    # sysadmin user limited to an insufficient role
    user    = users(:southwest_admin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::LOGGED_IN)
    policy  = InstitutionPolicy.new(context, @institution)
    assert !policy.new?
  end

  # show?()

  test "show?() returns false with a nil request context" do
    policy = InstitutionPolicy.new(nil, @institution)
    assert !policy.show?
  end

  test "show?() does not authorize non-sysadmins" do
    user    = users(:southwest)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy = InstitutionPolicy.new(context, @institution)
    assert !policy.show?
  end

  test "show?() authorizes sysadmins" do
    user    = users(:local_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = InstitutionPolicy.new(context, @institution)
    assert policy.show?
  end

  test "show?() authorizes administrators of the same institution" do
    user    = users(:southwest_admin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = InstitutionPolicy.new(context, @institution)
    assert policy.show?
  end

  test "show?() does not authorize administrators of a different institution" do
    user    = users(:southwest_admin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = InstitutionPolicy.new(context, institutions(:uiuc))
    assert !policy.show?
  end

  test "show?() respects role limits" do
    # sysadmin user limited to an insufficient role
    user    = users(:southwest_admin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::LOGGED_IN)
    policy  = InstitutionPolicy.new(context, @institution)
    assert !policy.show?
  end

  # show_access?()

  test "show_access?() returns false with a nil user" do
    policy = InstitutionPolicy.new(nil, @institution)
    assert !policy.show_access?
  end

  test "show_access?() is restrictive by default" do
    user    = users(:norights)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = InstitutionPolicy.new(context, @institution)
    assert !policy.show_access?
  end

  test "show_access?() authorizes sysadmins" do
    user    = users(:local_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy = InstitutionPolicy.new(context, @institution)
    assert policy.show_access?
  end

  test "show_access?() respects role limits" do
    # sysadmin user limited to an insufficient role
    user    = users(:local_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::LOGGED_IN)
    policy  = InstitutionPolicy.new(context, @institution)
    assert !policy.show_access?
  end

  # show_preservation?()

  test "show_preservation?() returns false with a nil request context" do
    policy = InstitutionPolicy.new(nil, @institution)
    assert !policy.show_preservation?
  end

  test "show_preservation?() is restrictive by default" do
    user    = users(:southwest)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = InstitutionPolicy.new(context, @institution)
    assert !policy.show_preservation?
  end

  test "show_preservation?() authorizes sysadmins" do
    user    = users(:local_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = InstitutionPolicy.new(context, @institution)
    assert policy.show_preservation?
  end

  test "show_preservation?() respects role limits" do
    # sysadmin user limited to an insufficient role
    user    = users(:southwest_admin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::LOGGED_IN)
    policy  = InstitutionPolicy.new(context, @institution)
    assert !policy.show_preservation?
  end

  # show_properties?()

  test "show_properties?() returns false with a nil request context" do
    policy = InstitutionPolicy.new(nil, @institution)
    assert !policy.show_properties?
  end

  test "show_properties?() does not authorize non-sysadmins" do
    user    = users(:southwest)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy = InstitutionPolicy.new(context, @institution)
    assert !policy.show_properties?
  end

  test "show_properties?() authorizes sysadmins" do
    user    = users(:local_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = InstitutionPolicy.new(context, @institution)
    assert policy.show_properties?
  end

  test "show_properties?() authorizes administrators of the same institution" do
    user    = users(:southwest_admin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = InstitutionPolicy.new(context, @institution)
    assert policy.show_properties?
  end

  test "show_properties?() does not authorize administrators of a different
  institution" do
    user    = users(:southwest_admin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = InstitutionPolicy.new(context, institutions(:uiuc))
    assert !policy.show_properties?
  end

  test "show_properties?() respects role limits" do
    # sysadmin user limited to an insufficient role
    user    = users(:southwest_admin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::LOGGED_IN)
    policy  = InstitutionPolicy.new(context, @institution)
    assert !policy.show_properties?
  end

  # show_settings?()

  test "show_settings?() returns false with a nil request context" do
    policy = InstitutionPolicy.new(nil, @institution)
    assert !policy.show_settings?
  end

  test "show_settings?() does not authorize non-sysadmins" do
    user    = users(:southwest)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy = InstitutionPolicy.new(context, @institution)
    assert !policy.show_settings?
  end

  test "show_settings?() authorizes sysadmins" do
    user    = users(:local_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = InstitutionPolicy.new(context, @institution)
    assert policy.show_settings?
  end

  test "show_settings?() authorizes administrators of the same institution" do
    user    = users(:southwest_admin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = InstitutionPolicy.new(context, @institution)
    assert policy.show_settings?
  end

  test "show_settings?() does not authorize administrators of a different
  institution" do
    user    = users(:southwest_admin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = InstitutionPolicy.new(context, institutions(:uiuc))
    assert !policy.show_settings?
  end

  test "show_settings?() respects role limits" do
    # sysadmin user limited to an insufficient role
    user    = users(:southwest_admin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::LOGGED_IN)
    policy  = InstitutionPolicy.new(context, @institution)
    assert !policy.show_settings?
  end

  # show_statistics?()

  test "show_statistics?() returns false with a nil request context" do
    policy = InstitutionPolicy.new(nil, @institution)
    assert !policy.show_statistics?
  end

  test "show_statistics?() does not authorize non-sysadmins" do
    user    = users(:southwest)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy = InstitutionPolicy.new(context, @institution)
    assert !policy.show_statistics?
  end

  test "show_statistics?() authorizes sysadmins" do
    user    = users(:local_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = InstitutionPolicy.new(context, @institution)
    assert policy.show_statistics?
  end

  test "show_statistics?() authorizes administrators of the same institution" do
    user    = users(:southwest_admin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = InstitutionPolicy.new(context, @institution)
    assert policy.show_statistics?
  end

  test "show_statistics?() does not authorize administrators of a different
  institution" do
    user    = users(:southwest_admin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = InstitutionPolicy.new(context, institutions(:uiuc))
    assert !policy.show_statistics?
  end

  test "show_statistics?() respects role limits" do
    # sysadmin user limited to an insufficient role
    user    = users(:southwest_admin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::LOGGED_IN)
    policy  = InstitutionPolicy.new(context, @institution)
    assert !policy.show_statistics?
  end

  # show_theme?()

  test "show_theme?() returns false with a nil request context" do
    policy = InstitutionPolicy.new(nil, @institution)
    assert !policy.show_theme?
  end

  test "show_theme?() does not authorize non-sysadmins" do
    user    = users(:southwest)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy = InstitutionPolicy.new(context, @institution)
    assert !policy.show_theme?
  end

  test "show_theme?() authorizes sysadmins" do
    user    = users(:local_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = InstitutionPolicy.new(context, @institution)
    assert policy.show_theme?
  end

  test "show_theme?() authorizes administrators of the same institution" do
    user    = users(:southwest_admin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = InstitutionPolicy.new(context, @institution)
    assert policy.show_theme?
  end

  test "show_theme?() does not authorize administrators of a different
  institution" do
    user    = users(:southwest_admin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = InstitutionPolicy.new(context, institutions(:uiuc))
    assert !policy.show_theme?
  end

  test "show_theme?() respects role limits" do
    # sysadmin user limited to an insufficient role
    user    = users(:southwest_admin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::LOGGED_IN)
    policy  = InstitutionPolicy.new(context, @institution)
    assert !policy.show_theme?
  end

  # show_users?()

  test "show_users?() returns false with a nil request context" do
    policy = InstitutionPolicy.new(nil, @institution)
    assert !policy.show_users?
  end

  test "show_users?() does not authorize non-sysadmins" do
    user    = users(:southwest)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy = InstitutionPolicy.new(context, @institution)
    assert !policy.show_users?
  end

  test "show_users?() authorizes sysadmins" do
    user    = users(:local_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = InstitutionPolicy.new(context, @institution)
    assert policy.show_users?
  end

  test "show_users?() authorizes administrators of the same institution" do
    user    = users(:southwest_admin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = InstitutionPolicy.new(context, @institution)
    assert policy.show_users?
  end

  test "show_users?() does not authorize administrators of a different institution" do
    user    = users(:southwest_admin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = InstitutionPolicy.new(context, institutions(:uiuc))
    assert !policy.show_users?
  end

  test "show_users?() respects role limits" do
    # sysadmin user limited to an insufficient role
    user    = users(:southwest_admin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::LOGGED_IN)
    policy  = InstitutionPolicy.new(context, @institution)
    assert !policy.show_users?
  end

  # statistics_by_range?()

  test "statistics_by_range?() returns false with a nil user" do
    policy = InstitutionPolicy.new(nil, @institution)
    assert !policy.statistics_by_range?
  end

  test "statistics_by_range?() is restrictive by default" do
    user    = users(:norights)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = InstitutionPolicy.new(context, @institution)
    assert !policy.statistics_by_range?
  end

  test "statistics_by_range?() authorizes sysadmins" do
    user    = users(:local_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy = InstitutionPolicy.new(context, @institution)
    assert policy.statistics_by_range?
  end

  test "statistics_by_range?() authorizes administrators of the same
  institution" do
    user    = users(:southwest_admin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = InstitutionPolicy.new(context, @institution)
    assert policy.statistics_by_range?
  end

  test "statistics_by_range?() does not authorize administrators of a
  different institution" do
    user    = users(:southwest_admin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = InstitutionPolicy.new(context, institutions(:uiuc))
    assert !policy.statistics_by_range?
  end

  test "statistics_by_range?() respects role limits" do
    # sysadmin user limited to an insufficient role
    user    = users(:local_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::LOGGED_IN)
    policy  = InstitutionPolicy.new(context, @institution)
    assert !policy.statistics_by_range?
  end

  # update_preservation?()

  test "update_preservation?() returns false with a nil request context" do
    policy = InstitutionPolicy.new(nil, @institution)
    assert !policy.update_preservation?
  end

  test "update_preservation?() is restrictive by default" do
    user    = users(:southwest)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = InstitutionPolicy.new(context, @institution)
    assert !policy.update_preservation?
  end

  test "update_preservation?() authorizes sysadmins" do
    user    = users(:local_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = InstitutionPolicy.new(context, @institution)
    assert policy.update_preservation?
  end

  test "update_preservation?() respects role limits" do
    # sysadmin user limited to an insufficient role
    user    = users(:southwest_admin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::LOGGED_IN)
    policy  = InstitutionPolicy.new(context, @institution)
    assert !policy.update_preservation?
  end

  # update_properties?()

  test "update_properties?() returns false with a nil request context" do
    policy = InstitutionPolicy.new(nil, @institution)
    assert !policy.update_properties?
  end

  test "update_properties?() is restrictive by default" do
    user    = users(:southwest)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = InstitutionPolicy.new(context, @institution)
    assert !policy.update_properties?
  end

  test "update_properties?() authorizes sysadmins" do
    user    = users(:local_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = InstitutionPolicy.new(context, @institution)
    assert policy.update_properties?
  end

  test "update_properties?() respects role limits" do
    # sysadmin user limited to an insufficient role
    user    = users(:southwest_admin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::LOGGED_IN)
    policy  = InstitutionPolicy.new(context, @institution)
    assert !policy.update_properties?
  end

  # update_settings?()

  test "update_settings?() returns false with a nil request context" do
    policy = InstitutionPolicy.new(nil, @institution)
    assert !policy.update_settings?
  end

  test "update_settings?() is restrictive by default" do
    user    = users(:southwest)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = InstitutionPolicy.new(context, @institution)
    assert !policy.update_settings?
  end

  test "update_settings?() authorizes sysadmins" do
    user    = users(:local_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = InstitutionPolicy.new(context, @institution)
    assert policy.update_settings?
  end

  test "update_settings?() authorizes administrators of the same institution" do
    user    = users(:southwest_admin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = InstitutionPolicy.new(context, @institution)
    assert policy.update_settings?
  end

  test "update_settings?() does not authorize administrators of a different institution" do
    user    = users(:southwest_admin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = InstitutionPolicy.new(context, institutions(:uiuc))
    assert !policy.update_settings?
  end

  test "update_settings?() respects role limits" do
    # sysadmin user limited to an insufficient role
    user    = users(:southwest_admin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::LOGGED_IN)
    policy  = InstitutionPolicy.new(context, @institution)
    assert !policy.update_settings?
  end

end