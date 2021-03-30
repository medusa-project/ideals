require 'test_helper'

class InstitutionPolicyTest < ActiveSupport::TestCase

  setup do
    @institution = institutions(:somewhere)
  end

  # create?()

  test "create?() returns false with a nil user context" do
    policy = InstitutionPolicy.new(nil, @institution)
    assert !policy.create?
  end

  test "create?() is restrictive by default" do
    user    = users(:somewhere)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::NO_LIMIT)
    policy  = InstitutionPolicy.new(context, @institution)
    assert !policy.create?
  end

  test "create?() authorizes sysadmins" do
    user    = users(:local_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::NO_LIMIT)
    policy  = InstitutionPolicy.new(context, @institution)
    assert policy.create?
  end

  test "create?() respects role limits" do
    # sysadmin user limited to an insufficient role
    user    = users(:somewhere_admin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::LOGGED_IN)
    policy  = InstitutionPolicy.new(context, @institution)
    assert !policy.create?
  end

  # destroy?()

  test "destroy?() returns false with a nil user context" do
    policy = InstitutionPolicy.new(nil, @institution)
    assert !policy.destroy?
  end

  test "destroy?() is restrictive by default" do
    user    = users(:somewhere)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::NO_LIMIT)
    policy  = InstitutionPolicy.new(context, @institution)
    assert !policy.destroy?
  end

  test "destroy?() authorizes sysadmins" do
    user    = users(:local_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::NO_LIMIT)
    policy  = InstitutionPolicy.new(context, @institution)
    assert policy.destroy?
  end

  test "destroy?() respects role limits" do
    # sysadmin user limited to an insufficient role
    user    = users(:somewhere_admin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::LOGGED_IN)
    policy  = InstitutionPolicy.new(context, @institution)
    assert !policy.destroy?
  end

  # edit?()

  test "edit?() returns false with a nil user context" do
    policy = InstitutionPolicy.new(nil, @institution)
    assert !policy.edit?
  end

  test "edit?() is restrictive by default" do
    skip # TODO: enable this once User.institution_admin?() is implemented properly
    user    = users(:somewhere)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::NO_LIMIT)
    policy  = InstitutionPolicy.new(context, @institution)
    assert !policy.edit?
  end

  test "edit?() authorizes sysadmins" do
    user    = users(:local_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::NO_LIMIT)
    policy  = InstitutionPolicy.new(context, @institution)
    assert policy.edit?
  end

  test "edit?() authorizes administrators of the same institution" do
    user    = users(:somewhere_admin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::NO_LIMIT)
    policy  = InstitutionPolicy.new(context, user.institution)
    assert policy.edit?
  end

  test "edit?() does not authorize administrators of different institutions" do
    user    = users(:somewhere_admin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::NO_LIMIT)
    policy  = InstitutionPolicy.new(context, @institution)
    assert policy.edit?
  end

  test "edit?() respects role limits" do
    # sysadmin user limited to an insufficient role
    user    = users(:somewhere_admin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::LOGGED_IN)
    policy  = InstitutionPolicy.new(context, @institution)
    assert !policy.edit?
  end

  # index?()

  test "index?() returns false with a nil user context" do
    policy = InstitutionPolicy.new(nil, @institution)
    assert !policy.index?
  end

  test "index?() is restrictive by default" do
    user    = users(:somewhere)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::NO_LIMIT)
    policy  = InstitutionPolicy.new(context, @institution)
    assert !policy.index?
  end

  test "index?() authorizes sysadmins" do
    user    = users(:local_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::NO_LIMIT)
    policy  = InstitutionPolicy.new(context, @institution)
    assert policy.index?
  end

  test "index?() respects role limits" do
    # sysadmin user limited to an insufficient role
    user    = users(:somewhere_admin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::LOGGED_IN)
    policy  = InstitutionPolicy.new(context, @institution)
    assert !policy.index?
  end

  # item_download_counts?()

  test "item_download_counts?() returns false with a nil user" do
    policy = InstitutionPolicy.new(nil, @institution)
    assert !policy.item_download_counts?
  end

  test "item_download_counts?() is restrictive by default" do
    user    = users(:norights)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::NO_LIMIT)
    policy  = InstitutionPolicy.new(context, @institution)
    assert !policy.item_download_counts?
  end

  test "item_download_counts?() authorizes sysadmins" do
    user    = users(:local_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::NO_LIMIT)
    policy = InstitutionPolicy.new(context, @institution)
    assert policy.item_download_counts?
  end

  test "item_download_counts?() respects role limits" do
    # sysadmin user limited to an insufficient role
    user    = users(:local_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::LOGGED_IN)
    policy  = InstitutionPolicy.new(context, @institution)
    assert !policy.item_download_counts?
  end

  # new?()

  test "new?() returns false with a nil user context" do
    policy = InstitutionPolicy.new(nil, @institution)
    assert !policy.new?
  end

  test "new?() is restrictive by default" do
    user    = users(:somewhere)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::NO_LIMIT)
    policy  = InstitutionPolicy.new(context, @institution)
    assert !policy.new?
  end

  test "new?() authorizes sysadmins" do
    user    = users(:local_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::NO_LIMIT)
    policy  = InstitutionPolicy.new(context, @institution)
    assert policy.new?
  end

  test "new?() respects role limits" do
    # sysadmin user limited to an insufficient role
    user    = users(:somewhere_admin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::LOGGED_IN)
    policy  = InstitutionPolicy.new(context, @institution)
    assert !policy.new?
  end

  # show?()

  test "show?() returns false with a nil user context" do
    policy = InstitutionPolicy.new(nil, @institution)
    assert !policy.show?
  end

  test "show?() does not authorize non-sysadmins" do
    skip # TODO: enable this once User.institution_admin?() is properly implemented
    user    = users(:somewhere)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::NO_LIMIT)
    policy = InstitutionPolicy.new(context, @institution)
    assert !policy.show?
  end

  test "show?() authorizes sysadmins" do
    user    = users(:local_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::NO_LIMIT)
    policy  = InstitutionPolicy.new(context, @institution)
    assert policy.show?
  end

  test "show?() authorizes administrators of the same institution" do
    user    = users(:somewhere_admin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::NO_LIMIT)
    policy  = InstitutionPolicy.new(context, @institution)
    assert policy.show?
  end

  test "show?() does not authorize administrators of a different institution" do
    user    = users(:somewhere_admin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::NO_LIMIT)
    policy  = InstitutionPolicy.new(context, institutions(:uiuc))
    assert !policy.show?
  end

  test "show?() respects role limits" do
    # sysadmin user limited to an insufficient role
    user    = users(:somewhere_admin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::LOGGED_IN)
    policy  = InstitutionPolicy.new(context, @institution)
    assert !policy.show?
  end

  # statistics?()

  test "statistics?() returns false with a nil user context" do
    policy = InstitutionPolicy.new(nil, @institution)
    assert !policy.statistics?
  end

  test "statistics?() does not authorize non-sysadmins" do
    skip # TODO: enable this once User.institution_admin?() is properly implemented
    user    = users(:somewhere)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::NO_LIMIT)
    policy = InstitutionPolicy.new(context, @institution)
    assert !policy.statistics?
  end

  test "statistics?() authorizes sysadmins" do
    user    = users(:local_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::NO_LIMIT)
    policy  = InstitutionPolicy.new(context, @institution)
    assert policy.statistics?
  end

  test "statistics?() authorizes administrators of the same institution" do
    user    = users(:somewhere_admin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::NO_LIMIT)
    policy  = InstitutionPolicy.new(context, @institution)
    assert policy.statistics?
  end

  test "statistics?() does not authorize administrators of a different institution" do
    user    = users(:somewhere_admin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::NO_LIMIT)
    policy  = InstitutionPolicy.new(context, institutions(:uiuc))
    assert !policy.statistics?
  end

  test "statistics?() respects role limits" do
    # sysadmin user limited to an insufficient role
    user    = users(:somewhere_admin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::LOGGED_IN)
    policy  = InstitutionPolicy.new(context, @institution)
    assert !policy.statistics?
  end

  # statistics_by_range?()

  test "statistics_by_range?() returns false with a nil user" do
    policy = InstitutionPolicy.new(nil, @institution)
    assert !policy.statistics_by_range?
  end

  test "statistics_by_range?() is restrictive by default" do
    user    = users(:norights)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::NO_LIMIT)
    policy  = InstitutionPolicy.new(context, @institution)
    assert !policy.statistics_by_range?
  end

  test "statistics_by_range?() authorizes sysadmins" do
    user    = users(:local_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::NO_LIMIT)
    policy = InstitutionPolicy.new(context, @institution)
    assert policy.statistics_by_range?
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

  # update?()

  test "update?() returns false with a nil user context" do
    policy = InstitutionPolicy.new(nil, @institution)
    assert !policy.update?
  end

  test "update?() is restrictive by default" do
    skip # TODO: enable this once User.institution_admin?() is implemented properly
    user    = users(:somewhere)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::NO_LIMIT)
    policy  = InstitutionPolicy.new(context, @institution)
    assert !policy.update?
  end

  test "update?() authorizes sysadmins" do
    user    = users(:local_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::NO_LIMIT)
    policy  = InstitutionPolicy.new(context, @institution)
    assert policy.update?
  end

  test "update?() authorizes administrators of the same institution" do
    user    = users(:somewhere_admin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::NO_LIMIT)
    policy  = InstitutionPolicy.new(context, user.institution)
    assert policy.update?
  end

  test "update?() does not authorize administrators of different institutions" do
    user    = users(:somewhere_admin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::NO_LIMIT)
    policy  = InstitutionPolicy.new(context, @institution)
    assert policy.update?
  end

  test "update?() respects role limits" do
    # sysadmin user limited to an insufficient role
    user    = users(:somewhere_admin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::LOGGED_IN)
    policy  = InstitutionPolicy.new(context, @institution)
    assert !policy.update?
  end

end