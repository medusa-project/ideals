require 'test_helper'

class ElementNamespacePolicyTest < ActiveSupport::TestCase

  setup do
    @namespace = element_namespaces(:southwest_dc)
  end

  # create?()

  test "create?() returns false with a nil user" do
    context = RequestContext.new(user:        nil,
                                 institution: @namespace.institution)
    policy = ElementNamespacePolicy.new(context, @namespace)
    assert !policy.create?
  end

  test "create?() does not authorize non-privileged users" do
    user    = users(:southwest)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = ElementNamespacePolicy.new(context, @namespace)
    assert !policy.create?
  end

  test "create?() authorizes administrators of the same institution" do
    user = users(:southwest_admin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = ElementNamespacePolicy.new(context, @namespace)
    assert policy.create?
  end

  test "create?() does not authorize administrators of a different
  institution than in the request context" do
    user    = users(:southwest_admin)
    context = RequestContext.new(user:        user,
                                 institution: institutions(:northeast))
    policy  = ElementNamespacePolicy.new(context, @namespace)
    assert !policy.create?
  end

  test "create?() respects role limits" do
    # sysadmin user limited to an insufficient role
    user    = users(:southwest_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::LOGGED_IN)
    policy  = ElementNamespacePolicy.new(context, @namespace)
    assert !policy.create?
  end

  # destroy?()

  test "destroy?() returns false with a nil user" do
    context = RequestContext.new(user:        nil,
                                 institution: @namespace.institution)
    policy = ElementNamespacePolicy.new(context, @namespace)
    assert !policy.destroy?
  end

  test "destroy?() does not authorize an incorrect scope" do
    context = RequestContext.new(user:        users(:southwest_admin),
                                 institution: institutions(:northeast))
    policy  = ElementNamespacePolicy.new(context, @namespace)
    assert !policy.destroy?
  end

  test "destroy?() does not authorize non-privileged users" do
    user    = users(:southwest)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = ElementNamespacePolicy.new(context, @namespace)
    assert !policy.destroy?
  end

  test "destroy?() authorizes administrators of the same institution" do
    user = users(:southwest_admin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = ElementNamespacePolicy.new(context, @namespace)
    assert policy.destroy?
  end

  test "destroy?() does not authorize administrators of a different
  institution than in the request context" do
    user    = users(:southwest_admin)
    context = RequestContext.new(user:        user,
                                 institution: institutions(:northeast))
    policy  = ElementNamespacePolicy.new(context, @namespace)
    assert !policy.destroy?
  end

  test "destroy?() does not authorize administrators of a different
  institution than the metadata profile" do
    user    = users(:northeast_admin)
    context = RequestContext.new(user:        user,
                                 institution: institutions(:northeast))
    policy  = ElementNamespacePolicy.new(context, @namespace)
    assert !policy.destroy?
  end

  test "destroy?() respects role limits" do
    # sysadmin user limited to an insufficient role
    user    = users(:southwest_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::LOGGED_IN)
    policy  = ElementNamespacePolicy.new(context, @namespace)
    assert !policy.destroy?
  end

  # edit?()

  test "edit?() returns false with a nil user" do
    context = RequestContext.new(user:        nil,
                                 institution: @namespace.institution)
    policy = ElementNamespacePolicy.new(context, @namespace)
    assert !policy.edit?
  end

  test "edit?() does not authorize an incorrect scope" do
    context = RequestContext.new(user:        users(:southwest_admin),
                                 institution: institutions(:northeast))
    policy  = ElementNamespacePolicy.new(context, @namespace)
    assert !policy.edit?
  end

  test "edit?() does not authorize non-privileged users" do
    user    = users(:southwest)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = ElementNamespacePolicy.new(context, @namespace)
    assert !policy.edit?
  end

  test "edit?() authorizes administrators of the same institution" do
    user = users(:southwest_admin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = ElementNamespacePolicy.new(context, @namespace)
    assert policy.edit?
  end

  test "edit?() does not authorize administrators of a different
  institution than in the request context" do
    user    = users(:southwest_admin)
    context = RequestContext.new(user:        user,
                                 institution: institutions(:northeast))
    policy  = ElementNamespacePolicy.new(context, @namespace)
    assert !policy.edit?
  end

  test "edit?() does not authorize administrators of a different
  institution than the metadata profile" do
    user    = users(:northeast_admin)
    context = RequestContext.new(user:        user,
                                 institution: institutions(:northeast))
    policy  = ElementNamespacePolicy.new(context, @namespace)
    assert !policy.edit?
  end

  test "edit?() respects role limits" do
    # sysadmin user limited to an insufficient role
    user    = users(:southwest_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::LOGGED_IN)
    policy  = ElementNamespacePolicy.new(context, @namespace)
    assert !policy.edit?
  end

  # index?()

  test "index?() returns false with a nil user" do
    context = RequestContext.new(user:        nil,
                                 institution: @namespace.institution)
    policy = ElementNamespacePolicy.new(context, MetadataProfile)
    assert !policy.index?
  end

  test "index?() does not authorize non-privileged users" do
    user    = users(:southwest)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = ElementNamespacePolicy.new(context, MetadataProfile)
    assert !policy.index?
  end

  test "index?() authorizes institution administrators" do
    user    = users(:southwest_admin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = ElementNamespacePolicy.new(context, @namespace)
    assert policy.index?
  end

  test "index?() does not authorize administrators of a different
  institution than in the request context" do
    user    = users(:southwest_admin)
    context = RequestContext.new(user:        user,
                                 institution: institutions(:northeast))
    policy  = ElementNamespacePolicy.new(context, @namespace)
    assert !policy.index?
  end

  test "index?() respects role limits" do
    # sysadmin user limited to an insufficient role
    user    = users(:southwest_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::LOGGED_IN)
    policy  = ElementNamespacePolicy.new(context, @namespace)
    assert !policy.index?
  end

  # new()

  test "new?() returns false with a nil user" do
    context = RequestContext.new(user:        nil,
                                 institution: @namespace.institution)
    policy = ElementNamespacePolicy.new(context, @namespace)
    assert !policy.new?
  end

  test "new?() does not authorize non-privileged users" do
    user    = users(:southwest)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy = ElementNamespacePolicy.new(context, @namespace)
    assert !policy.new?
  end

  test "new?() authorizes institution administrators" do
    user = users(:southwest_admin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = ElementNamespacePolicy.new(context, @namespace)
    assert policy.new?
  end

  test "new?() does not authorize administrators of a different
  institution than in the request context" do
    user    = users(:southwest_admin)
    context = RequestContext.new(user:        user,
                                 institution: institutions(:northeast))
    policy  = ElementNamespacePolicy.new(context, @namespace)
    assert !policy.new?
  end

  test "new?() respects role limits" do
    # sysadmin user limited to an insufficient role
    user    = users(:southwest_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::LOGGED_IN)
    policy  = ElementNamespacePolicy.new(context, @namespace)
    assert !policy.new?
  end

  # update?()

  test "update?() returns false with a nil user" do
    context = RequestContext.new(user:        nil,
                                 institution: @namespace.institution)
    policy = ElementNamespacePolicy.new(context, @namespace)
    assert !policy.update?
  end

  test "update?() does not authorize an incorrect scope" do
    context = RequestContext.new(user:        users(:southwest_admin),
                                 institution: institutions(:northeast))
    policy  = ElementNamespacePolicy.new(context, @namespace)
    assert !policy.update?
  end

  test "update?() does not authorize non-privileged users" do
    user    = users(:southwest)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy = ElementNamespacePolicy.new(context, @namespace)
    assert !policy.update?
  end

  test "update?() authorizes administrators of the same institution" do
    user = users(:southwest_admin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = ElementNamespacePolicy.new(context, @namespace)
    assert policy.update?
  end

  test "update?() does not authorize administrators of a different
  institution than in the request context" do
    user    = users(:southwest_admin)
    context = RequestContext.new(user:        user,
                                 institution: institutions(:northeast))
    policy  = ElementNamespacePolicy.new(context, @namespace)
    assert !policy.update?
  end

  test "update?() does not authorize administrators of a different
  institution than the metadata profile" do
    user    = users(:northeast_admin)
    context = RequestContext.new(user:        user,
                                 institution: institutions(:northeast))
    policy  = ElementNamespacePolicy.new(context, @namespace)
    assert !policy.update?
  end

  test "update?() respects role limits" do
    # sysadmin user limited to an insufficient role
    user    = users(:southwest_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::LOGGED_IN)
    policy  = ElementNamespacePolicy.new(context, @namespace)
    assert !policy.update?
  end

end
