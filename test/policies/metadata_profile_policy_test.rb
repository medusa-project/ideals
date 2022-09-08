require 'test_helper'

class MetadataProfilePolicyTest < ActiveSupport::TestCase

  setup do
    @user    = users(:norights)
    @profile = metadata_profiles(:default)
  end

  # clone?()

  test "clone?() returns false with a nil user" do
    policy = MetadataProfilePolicy.new(nil, @profile)
    assert !policy.clone?
  end

  test "clone?() does not authorize non-sysadmins" do
    user    = users(:norights)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = MetadataProfilePolicy.new(context, @profile)
    assert !policy.clone?
  end

  test "clone?() authorizes sysadmins" do
    user    = users(:local_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = MetadataProfilePolicy.new(context, @profile)
    assert policy.clone?
  end

  test "clone?() authorizes administrators of the same institution" do
    user = users(:southwest_admin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = MetadataProfilePolicy.new(context, @element)
    assert policy.clone?
  end

  test "clone?() does not authorize administrators of a different
  institution" do
    user    = users(:southwest_admin)
    context = RequestContext.new(user:        user,
                                 institution: institutions(:northeast))
    policy  = MetadataProfilePolicy.new(context, @element)
    assert !policy.clone?
  end

  test "clone?() respects role limits" do
    # sysadmin user limited to an insufficient role
    user    = users(:local_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::LOGGED_IN)
    policy  = MetadataProfilePolicy.new(context, @profile)
    assert !policy.clone?
  end

  # create?()

  test "create?() returns false with a nil user" do
    policy = MetadataProfilePolicy.new(nil, @profile)
    assert !policy.create?
  end

  test "create?() does not authorize non-sysadmins" do
    user    = users(:norights)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = MetadataProfilePolicy.new(context, @profile)
    assert !policy.create?
  end

  test "create?() authorizes sysadmins" do
    user    = users(:local_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = MetadataProfilePolicy.new(context, @profile)
    assert policy.create?
  end

  test "create?() authorizes administrators of the same institution" do
    user = users(:southwest_admin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = MetadataProfilePolicy.new(context, @element)
    assert policy.create?
  end

  test "create?() does not authorize administrators of a different
  institution" do
    user    = users(:southwest_admin)
    context = RequestContext.new(user:        user,
                                 institution: institutions(:northeast))
    policy  = MetadataProfilePolicy.new(context, @element)
    assert !policy.create?
  end

  test "create?() respects role limits" do
    # sysadmin user limited to an insufficient role
    user    = users(:local_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::LOGGED_IN)
    policy  = MetadataProfilePolicy.new(context, @profile)
    assert !policy.create?
  end

  # destroy?()

  test "destroy?() returns false with a nil user" do
    policy = MetadataProfilePolicy.new(nil, @profile)
    assert !policy.destroy?
  end

  test "destroy?() does not authorize non-sysadmins" do
    user    = users(:norights)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = MetadataProfilePolicy.new(context, @profile)
    assert !policy.destroy?
  end

  test "destroy?() authorizes sysadmins" do
    user    = users(:local_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = MetadataProfilePolicy.new(context, @profile)
    assert policy.destroy?
  end

  test "destroy?() authorizes administrators of the same institution" do
    user = users(:southwest_admin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = MetadataProfilePolicy.new(context, @element)
    assert policy.destroy?
  end

  test "destroy?() does not authorize administrators of a different
  institution" do
    user    = users(:southwest_admin)
    context = RequestContext.new(user:        user,
                                 institution: institutions(:northeast))
    policy  = MetadataProfilePolicy.new(context, @element)
    assert !policy.destroy?
  end

  test "destroy?() respects role limits" do
    # sysadmin user limited to an insufficient role
    user    = users(:local_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::LOGGED_IN)
    policy  = MetadataProfilePolicy.new(context, @profile)
    assert !policy.destroy?
  end

  # edit?()

  test "edit?() returns false with a nil user" do
    policy = MetadataProfilePolicy.new(nil, @profile)
    assert !policy.edit?
  end

  test "edit?() does not authorize non-sysadmins" do
    user    = users(:norights)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = MetadataProfilePolicy.new(context, @profile)
    assert !policy.edit?
  end

  test "edit?() authorizes sysadmins" do
    user    = users(:local_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = MetadataProfilePolicy.new(context, @profile)
    assert policy.edit?
  end

  test "edit?() authorizes administrators of the same institution" do
    user = users(:southwest_admin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = MetadataProfilePolicy.new(context, @element)
    assert policy.edit?
  end

  test "edit?() does not authorize administrators of a different
  institution" do
    user    = users(:southwest_admin)
    context = RequestContext.new(user:        user,
                                 institution: institutions(:northeast))
    policy  = MetadataProfilePolicy.new(context, @element)
    assert !policy.edit?
  end

  test "edit?() respects role limits" do
    # sysadmin user limited to an insufficient role
    user    = users(:local_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::LOGGED_IN)
    policy  = MetadataProfilePolicy.new(context, @profile)
    assert !policy.edit?
  end

  # index?()

  test "index?() returns false with a nil user" do
    policy = MetadataProfilePolicy.new(nil, MetadataProfile)
    assert !policy.index?
  end

  test "index?() does not authorize non-sysadmins" do
    user    = users(:norights)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = MetadataProfilePolicy.new(context, MetadataProfile)
    assert !policy.index?
  end

  test "index?() authorizes sysadmins" do
    user    = users(:local_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = MetadataProfilePolicy.new(context, MetadataProfile)
    assert policy.index?
  end

  test "index?() authorizes administrators of the same institution" do
    user = users(:southwest_admin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = MetadataProfilePolicy.new(context, @element)
    assert policy.index?
  end

  test "index?() does not authorize administrators of a different
  institution" do
    user    = users(:southwest_admin)
    context = RequestContext.new(user:        user,
                                 institution: institutions(:northeast))
    policy  = MetadataProfilePolicy.new(context, @element)
    assert !policy.index?
  end

  test "index?() respects role limits" do
    # sysadmin user limited to an insufficient role
    user    = users(:local_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::LOGGED_IN)
    policy  = MetadataProfilePolicy.new(context, @profile)
    assert !policy.index?
  end

  # new()

  test "new?() returns false with a nil user" do
    policy = MetadataProfilePolicy.new(nil, @profile)
    assert !policy.new?
  end

  test "new?() does not authorize non-sysadmins" do
    user    = users(:norights)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy = MetadataProfilePolicy.new(context, @profile)
    assert !policy.new?
  end

  test "new?() authorizes sysadmins" do
    user    = users(:local_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy = MetadataProfilePolicy.new(context, @profile)
    assert policy.new?
  end

  test "new?() authorizes administrators of the same institution" do
    user = users(:southwest_admin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = MetadataProfilePolicy.new(context, @element)
    assert policy.new?
  end

  test "new?() does not authorize administrators of a different
  institution" do
    user    = users(:southwest_admin)
    context = RequestContext.new(user:        user,
                                 institution: institutions(:northeast))
    policy  = MetadataProfilePolicy.new(context, @element)
    assert !policy.new?
  end

  test "new?() respects role limits" do
    # sysadmin user limited to an insufficient role
    user    = users(:local_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::LOGGED_IN)
    policy  = MetadataProfilePolicy.new(context, @profile)
    assert !policy.new?
  end

  # show?()

  test "show?() returns false with a nil user" do
    policy = MetadataProfilePolicy.new(nil, @profile)
    assert !policy.show?
  end

  test "show?() does not authorize non-sysadmins" do
    user    = users(:norights)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy = MetadataProfilePolicy.new(context, @profile)
    assert !policy.show?
  end

  test "show?() authorizes sysadmins" do
    user    = users(:local_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy = MetadataProfilePolicy.new(context, @profile)
    assert policy.show?
  end

  test "show?() authorizes administrators of the same institution" do
    user = users(:southwest_admin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = MetadataProfilePolicy.new(context, @element)
    assert policy.show?
  end

  test "show?() does not authorize administrators of a different
  institution" do
    user    = users(:southwest_admin)
    context = RequestContext.new(user:        user,
                                 institution: institutions(:northeast))
    policy  = MetadataProfilePolicy.new(context, @element)
    assert !policy.show?
  end

  test "show?() respects role limits" do
    # sysadmin user limited to an insufficient role
    user    = users(:local_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::LOGGED_IN)
    policy  = MetadataProfilePolicy.new(context, @profile)
    assert !policy.show?
  end

  # update?()

  test "update?() returns false with a nil user" do
    policy = MetadataProfilePolicy.new(nil, @profile)
    assert !policy.update?
  end

  test "update?() does not authorize non-sysadmins" do
    user    = users(:norights)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy = MetadataProfilePolicy.new(context, @profile)
    assert !policy.update?
  end

  test "update?() authorizes sysadmins" do
    user    = users(:local_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy = MetadataProfilePolicy.new(context, @profile)
    assert policy.update?
  end

  test "update?() authorizes administrators of the same institution" do
    user = users(:southwest_admin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = MetadataProfilePolicy.new(context, @element)
    assert policy.update?
  end

  test "update?() does not authorize administrators of a different
  institution" do
    user    = users(:southwest_admin)
    context = RequestContext.new(user:        user,
                                 institution: institutions(:northeast))
    policy  = MetadataProfilePolicy.new(context, @element)
    assert !policy.update?
  end

  test "update?() respects role limits" do
    # sysadmin user limited to an insufficient role
    user    = users(:local_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::LOGGED_IN)
    policy  = MetadataProfilePolicy.new(context, @profile)
    assert !policy.show?
  end

end
