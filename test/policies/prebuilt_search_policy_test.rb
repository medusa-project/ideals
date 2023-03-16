require 'test_helper'

class PrebuiltSearchPolicyTest < ActiveSupport::TestCase

  setup do
    @prebuilt_search = prebuilt_searches(:southwest_creators)
  end

  # create?()

  test "create?() returns false with a nil user" do
    context = RequestContext.new(user:        nil,
                                 institution: @prebuilt_search.institution)
    policy = PrebuiltSearchPolicy.new(context, @prebuilt_search)
    assert !policy.create?
  end

  test "create?() does not authorize an incorrect scope" do
    context = RequestContext.new(user:        users(:southwest_admin),
                                 institution: institutions(:northeast))
    policy  = PrebuiltSearchPolicy.new(context, @prebuilt_search)
    assert !policy.create?
  end

  test "create?() does not authorize non-sysadmins" do
    user    = users(:southwest)
    context = RequestContext.new(user:        user,
                                 institution: @prebuilt_search.institution)
    policy  = PrebuiltSearchPolicy.new(context, @prebuilt_search)
    assert !policy.create?
  end

  test "create?() authorizes sysadmins" do
    user    = users(:southwest_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: @prebuilt_search.institution)
    policy  = PrebuiltSearchPolicy.new(context, @prebuilt_search)
    assert policy.create?
  end

  test "create?() authorizes administrators of the same institution" do
    user = users(:southwest_admin)
    context = RequestContext.new(user:        user,
                                 institution: @prebuilt_search.institution)
    policy  = PrebuiltSearchPolicy.new(context, @prebuilt_search)
    assert policy.create?
  end

  test "create?() does not authorize administrators of a different
  institution" do
    user    = users(:southwest_admin)
    context = RequestContext.new(user:        user,
                                 institution: institutions(:northeast))
    policy  = PrebuiltSearchPolicy.new(context, @prebuilt_search)
    assert !policy.create?
  end

  test "create?() respects role limits" do
    # sysadmin user limited to an insufficient role
    user    = users(:southwest_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: @prebuilt_search.institution,
                                 role_limit:  Role::LOGGED_IN)
    policy  = PrebuiltSearchPolicy.new(context, @prebuilt_search)
    assert !policy.create?
  end

  # destroy?()

  test "destroy?() returns false with a nil user" do
    context = RequestContext.new(user:        nil,
                                 institution: @prebuilt_search.institution)
    policy = PrebuiltSearchPolicy.new(context, @prebuilt_search)
    assert !policy.destroy?
  end

  test "destroy?() does not authorize an incorrect scope" do
    context = RequestContext.new(user:        users(:southwest_admin),
                                 institution: institutions(:northeast))
    policy  = PrebuiltSearchPolicy.new(context, @prebuilt_search)
    assert !policy.destroy?
  end

  test "destroy?() does not authorize non-sysadmins" do
    user    = users(:southwest)
    context = RequestContext.new(user:        user,
                                 institution: @prebuilt_search.institution)
    policy  = PrebuiltSearchPolicy.new(context, @prebuilt_search)
    assert !policy.destroy?
  end

  test "destroy?() authorizes sysadmins" do
    user    = users(:southwest_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: @prebuilt_search.institution)
    policy  = PrebuiltSearchPolicy.new(context, @prebuilt_search)
    assert policy.destroy?
  end

  test "destroy?() authorizes administrators of the same institution" do
    user = users(:southwest_admin)
    context = RequestContext.new(user:        user,
                                 institution: @prebuilt_search.institution)
    policy  = PrebuiltSearchPolicy.new(context, @prebuilt_search)
    assert policy.destroy?
  end

  test "destroy?() does not authorize administrators of a different
  institution" do
    user    = users(:southwest_admin)
    context = RequestContext.new(user:        user,
                                 institution: institutions(:northeast))
    policy  = PrebuiltSearchPolicy.new(context, @prebuilt_search)
    assert !policy.destroy?
  end

  test "destroy?() respects role limits" do
    # sysadmin user limited to an insufficient role
    user    = users(:southwest_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: @prebuilt_search.institution,
                                 role_limit:  Role::LOGGED_IN)
    policy  = PrebuiltSearchPolicy.new(context, @prebuilt_search)
    assert !policy.destroy?
  end

  # edit?()

  test "edit?() returns false with a nil user" do
    context = RequestContext.new(user:        nil,
                                 institution: @prebuilt_search.institution)
    policy = PrebuiltSearchPolicy.new(context, @prebuilt_search)
    assert !policy.edit?
  end

  test "edit?() does not authorize an incorrect scope" do
    context = RequestContext.new(user:        users(:southwest_admin),
                                 institution: institutions(:northeast))
    policy  = PrebuiltSearchPolicy.new(context, @prebuilt_search)
    assert !policy.edit?
  end

  test "edit?() does not authorize non-sysadmins" do
    user    = users(:southwest)
    context = RequestContext.new(user:        user,
                                 institution: @prebuilt_search.institution)
    policy  = PrebuiltSearchPolicy.new(context, @prebuilt_search)
    assert !policy.edit?
  end

  test "edit?() authorizes sysadmins" do
    user    = users(:southwest_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: @prebuilt_search.institution)
    policy  = PrebuiltSearchPolicy.new(context, @prebuilt_search)
    assert policy.edit?
  end

  test "edit?() authorizes administrators of the same institution" do
    user = users(:southwest_admin)
    context = RequestContext.new(user:        user,
                                 institution: @prebuilt_search.institution)
    policy  = PrebuiltSearchPolicy.new(context, @prebuilt_search)
    assert policy.edit?
  end

  test "edit?() does not authorize administrators of a different
  institution" do
    user    = users(:southwest_admin)
    context = RequestContext.new(user:        user,
                                 institution: institutions(:northeast))
    policy  = PrebuiltSearchPolicy.new(context, @prebuilt_search)
    assert !policy.edit?
  end

  test "edit?() respects role limits" do
    # sysadmin user limited to an insufficient role
    user    = users(:southwest_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: @prebuilt_search.institution,
                                 role_limit:  Role::LOGGED_IN)
    policy  = PrebuiltSearchPolicy.new(context, @prebuilt_search)
    assert !policy.edit?
  end

  # index?()

  test "index?() returns false with a nil user" do
    context = RequestContext.new(user:        nil,
                                 institution: @prebuilt_search.institution)
    policy = PrebuiltSearchPolicy.new(context, PrebuiltSearch)
    assert !policy.index?
  end

  test "index?() does not authorize an incorrect scope" do
    context = RequestContext.new(user:        users(:southwest_admin),
                                 institution: institutions(:northeast))
    policy  = PrebuiltSearchPolicy.new(context, PrebuiltSearch)
    assert !policy.index?
  end

  test "index?() does not authorize non-sysadmins" do
    user    = users(:southwest)
    context = RequestContext.new(user:        user,
                                 institution: @prebuilt_search.institution)
    policy  = PrebuiltSearchPolicy.new(context, PrebuiltSearch)
    assert !policy.index?
  end

  test "index?() authorizes sysadmins" do
    user    = users(:southwest_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: @prebuilt_search.institution)
    policy  = PrebuiltSearchPolicy.new(context, PrebuiltSearch)
    assert policy.index?
  end

  test "index?() authorizes administrators of the same institution" do
    user = users(:southwest_admin)
    context = RequestContext.new(user:        user,
                                 institution: @prebuilt_search.institution)
    policy  = PrebuiltSearchPolicy.new(context, @prebuilt_search)
    assert policy.index?
  end

  test "index?() does not authorize administrators of a different
  institution" do
    user    = users(:southwest_admin)
    context = RequestContext.new(user:        user,
                                 institution: institutions(:northeast))
    policy  = PrebuiltSearchPolicy.new(context, @prebuilt_search)
    assert !policy.index?
  end

  test "index?() respects role limits" do
    # sysadmin user limited to an insufficient role
    user    = users(:southwest_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: @prebuilt_search.institution,
                                 role_limit:  Role::LOGGED_IN)
    policy  = PrebuiltSearchPolicy.new(context, @prebuilt_search)
    assert !policy.index?
  end

  # new()

  test "new?() returns false with a nil user" do
    context = RequestContext.new(user:        nil,
                                 institution: @prebuilt_search.institution)
    policy = PrebuiltSearchPolicy.new(context, @prebuilt_search)
    assert !policy.new?
  end

  test "new?() does not authorize an incorrect scope" do
    context = RequestContext.new(user:        users(:southwest_admin),
                                 institution: institutions(:northeast))
    policy  = PrebuiltSearchPolicy.new(context, @prebuilt_search)
    assert !policy.new?
  end

  test "new?() does not authorize non-sysadmins" do
    user    = users(:southwest)
    context = RequestContext.new(user:        user,
                                 institution: @prebuilt_search.institution)
    policy = PrebuiltSearchPolicy.new(context, @prebuilt_search)
    assert !policy.new?
  end

  test "new?() authorizes sysadmins" do
    user    = users(:southwest_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: @prebuilt_search.institution)
    policy = PrebuiltSearchPolicy.new(context, @prebuilt_search)
    assert policy.new?
  end

  test "new?() authorizes administrators of the same institution" do
    user = users(:southwest_admin)
    context = RequestContext.new(user:        user,
                                 institution: @prebuilt_search.institution)
    policy  = PrebuiltSearchPolicy.new(context, @prebuilt_search)
    assert policy.new?
  end

  test "new?() does not authorize administrators of a different
  institution" do
    user    = users(:southwest_admin)
    context = RequestContext.new(user:        user,
                                 institution: institutions(:northeast))
    policy  = PrebuiltSearchPolicy.new(context, @prebuilt_search)
    assert !policy.new?
  end

  test "new?() respects role limits" do
    # sysadmin user limited to an insufficient role
    user    = users(:southwest_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: @prebuilt_search.institution,
                                 role_limit:  Role::LOGGED_IN)
    policy  = PrebuiltSearchPolicy.new(context, @prebuilt_search)
    assert !policy.new?
  end

  # show?()

  test "show?() authorizes requests to the same institution" do
    context = RequestContext.new(institution: @prebuilt_search.institution)
    policy  = PrebuiltSearchPolicy.new(context, @prebuilt_search)
    assert policy.show?
  end

  test "show?() does not authorize an incorrect scope" do
    context = RequestContext.new(user:        users(:southwest_admin),
                                 institution: institutions(:northeast))
    policy  = PrebuiltSearchPolicy.new(context, @prebuilt_search)
    assert !policy.show?
  end

  test "show?() does not authorize requests to a different institution" do
    context = RequestContext.new(institution: institutions(:northeast))
    policy  = PrebuiltSearchPolicy.new(context, @prebuilt_search)
    assert !policy.show?
  end

  # update?()

  test "update?() returns false with a nil user" do
    context = RequestContext.new(user:        nil,
                                 institution: @prebuilt_search.institution)
    policy = PrebuiltSearchPolicy.new(context, @prebuilt_search)
    assert !policy.update?
  end

  test "update?() does not authorize an incorrect scope" do
    context = RequestContext.new(user:        users(:southwest_admin),
                                 institution: institutions(:northeast))
    policy  = PrebuiltSearchPolicy.new(context, @prebuilt_search)
    assert !policy.update?
  end

  test "update?() does not authorize non-sysadmins" do
    user    = users(:southwest)
    context = RequestContext.new(user:        user,
                                 institution: @prebuilt_search.institution)
    policy = PrebuiltSearchPolicy.new(context, @prebuilt_search)
    assert !policy.update?
  end

  test "update?() authorizes sysadmins" do
    user    = users(:southwest_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: @prebuilt_search.institution)
    policy = PrebuiltSearchPolicy.new(context, @prebuilt_search)
    assert policy.update?
  end

  test "update?() authorizes administrators of the same institution" do
    user = users(:southwest_admin)
    context = RequestContext.new(user:        user,
                                 institution: @prebuilt_search.institution)
    policy  = PrebuiltSearchPolicy.new(context, @prebuilt_search)
    assert policy.update?
  end

  test "update?() does not authorize administrators of a different
  institution" do
    user    = users(:southwest_admin)
    context = RequestContext.new(user:        user,
                                 institution: institutions(:northeast))
    policy  = PrebuiltSearchPolicy.new(context, @prebuilt_search)
    assert !policy.update?
  end

  test "update?() respects role limits" do
    # sysadmin user limited to an insufficient role
    user    = users(:southwest_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: @prebuilt_search.institution,
                                 role_limit:  Role::LOGGED_IN)
    policy  = PrebuiltSearchPolicy.new(context, @prebuilt_search)
    assert !policy.update?
  end

end
