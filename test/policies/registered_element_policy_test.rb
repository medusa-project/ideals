require 'test_helper'

class RegisteredElementPolicyTest < ActiveSupport::TestCase

  setup do
    @element = registered_elements(:southwest_dc_title)
  end

  # create?()

  test "create?() returns false with a nil user" do
    context = RequestContext.new(user:        nil,
                                 institution: @element.institution)
    policy = RegisteredElementPolicy.new(context, @element)
    assert !policy.create?
  end

  test "create?() does not authorize users with no privileges" do
    user    = users(:southwest)
    context = RequestContext.new(user:        user,
                                 institution: @element.institution)
    policy  = RegisteredElementPolicy.new(context, @element)
    assert !policy.create?
  end

  test "create?() authorizes sysadmins" do
    user    = users(:southwest_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: @element.institution)
    policy  = RegisteredElementPolicy.new(context, @element)
    assert policy.create?
  end

  test "create?() authorizes administrators of the same institution" do
    user    = users(:southwest_admin)
    context = RequestContext.new(user:        user,
                                 institution: @element.institution)
    policy  = RegisteredElementPolicy.new(context, @element)
    assert policy.create?
  end

  test "create?() does not authorize administrators of a different institution
  as in the request context" do
    user    = users(:southwest_admin)
    context = RequestContext.new(user:        user,
                                 institution: institutions(:northeast))
    policy  = RegisteredElementPolicy.new(context, @element)
    assert !policy.create?
  end

  test "create?() respects role limits" do
    # sysadmin user limited to an insufficient role
    user    = users(:southwest_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: @element.institution,
                                 role_limit:  Role::LOGGED_IN)
    policy  = RegisteredElementPolicy.new(context, @element)
    assert !policy.create?
  end

  # destroy?()

  test "destroy?() returns false with a nil user" do
    context = RequestContext.new(user:        nil,
                                 institution: @element.institution)
    policy = RegisteredElementPolicy.new(context, @element)
    assert !policy.destroy?
  end

  test "destroy?() does not authorize an incorrect scope" do
    context = RequestContext.new(user:        users(:southwest_admin),
                                 institution: institutions(:northeast))
    policy  = RegisteredElementPolicy.new(context, @element)
    assert !policy.destroy?
  end

  test "destroy?() does not authorize users with no privileges" do
    user    = users(:southwest)
    context = RequestContext.new(user:        user,
                                 institution: @element.institution)
    policy  = RegisteredElementPolicy.new(context, @element)
    assert !policy.destroy?
  end

  test "destroy?() authorizes sysadmins" do
    user    = users(:southwest_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: @element.institution)
    policy  = RegisteredElementPolicy.new(context, @element)
    assert policy.destroy?
  end

  test "destroy?() authorizes administrators of the same institution" do
    user    = users(:southwest_admin)
    context = RequestContext.new(user:        user,
                                 institution: @element.institution)
    policy  = RegisteredElementPolicy.new(context, @element)
    assert policy.destroy?
  end

  test "destroy?() does not authorize administrators of a different institution
  as in the request context" do
    user    = users(:southwest_admin)
    context = RequestContext.new(user:        user,
                                 institution: institutions(:northeast))
    policy  = RegisteredElementPolicy.new(context, @element)
    assert !policy.destroy?
  end

  test "destroy?() does not authorize administrators of a different institution
  than that of the element" do
    user    = users(:northeast_admin)
    context = RequestContext.new(user:        user,
                                 institution: institutions(:northeast))
    policy  = RegisteredElementPolicy.new(context, @element)
    assert !policy.destroy?
  end

  test "destroy?() respects role limits" do
    # sysadmin user limited to an insufficient role
    user    = users(:southwest_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::LOGGED_IN)
    policy  = RegisteredElementPolicy.new(context, @element)
    assert !policy.destroy?
  end

  # edit?()

  test "edit?() returns false with a nil user" do
    context = RequestContext.new(user:        nil,
                                 institution: @element.institution)
    policy = RegisteredElementPolicy.new(context, @element)
    assert !policy.edit?
  end

  test "edit?() does not authorize an incorrect scope" do
    context = RequestContext.new(user:        users(:southwest_admin),
                                 institution: institutions(:northeast))
    policy  = RegisteredElementPolicy.new(context, @element)
    assert !policy.edit?
  end

  test "edit?() does not authorize users with no privileges" do
    user    = users(:southwest)
    context = RequestContext.new(user:        user,
                                 institution: @element.institution)
    policy = RegisteredElementPolicy.new(context, @element)
    assert !policy.edit?
  end

  test "edit?() authorizes sysadmins" do
    user    = users(:southwest_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: @element.institution)
    policy  = RegisteredElementPolicy.new(context, @element)
    assert policy.edit?
  end

  test "edit?() authorizes administrators of the same institution" do
    user    = users(:southwest_admin)
    context = RequestContext.new(user:        user,
                                 institution: @element.institution)
    policy  = RegisteredElementPolicy.new(context, @element)
    assert policy.edit?
  end

  test "edit?() does not authorize administrators of a different institution as
  in the request context" do
    user    = users(:southwest_admin)
    context = RequestContext.new(user:        user,
                                 institution: institutions(:northeast))
    policy  = RegisteredElementPolicy.new(context, @element)
    assert !policy.edit?
  end

  test "edit?() does not authorize administrators of a different institution
  than that of the element" do
    user    = users(:northeast_admin)
    context = RequestContext.new(user:        user,
                                 institution: institutions(:northeast))
    policy  = RegisteredElementPolicy.new(context, @element)
    assert !policy.edit?
  end

  test "edit?() respects role limits" do
    # sysadmin user limited to an insufficient role
    user    = users(:southwest_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::LOGGED_IN)
    policy  = RegisteredElementPolicy.new(context, @element)
    assert !policy.edit?
  end

  # index?()

  test "index?() returns false with a nil user" do
    context = RequestContext.new(user:        nil,
                                 institution: @element.institution)
    policy = RegisteredElementPolicy.new(context, RegisteredElement)
    assert !policy.index?
  end

  test "index?() does not authorize users with no privileges" do
    user    = users(:southwest)
    context = RequestContext.new(user:        user,
                                 institution: @element.institution)
    policy  = RegisteredElementPolicy.new(context, RegisteredElement)
    assert !policy.index?
  end

  test "index?() authorizes sysadmins" do
    user    = users(:southwest_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: @element.institution)
    policy  = RegisteredElementPolicy.new(context, RegisteredElement)
    assert policy.index?
  end

  test "index?() authorizes institution administrators" do
    user    = users(:southwest_admin)
    context = RequestContext.new(user:        user,
                                 institution: @element.institution)
    policy  = RegisteredElementPolicy.new(context, RegisteredElement)
    assert policy.index?
  end

  test "index?() respects role limits" do
    # sysadmin user limited to an insufficient role
    user    = users(:southwest_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::LOGGED_IN)
    policy  = RegisteredElementPolicy.new(context, @element)
    assert !policy.index?
  end

  # index_template?()

  test "index_template?() returns false with a nil user" do
    policy = RegisteredElementPolicy.new(nil, Usage)
    assert !policy.index_template?
  end

  test "index_template?() does not authorize non-sysadmins" do
    user    = users(:example)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy = RegisteredElementPolicy.new(context, Usage)
    assert !policy.index_template?
  end

  test "index_template?() authorizes sysadmins" do
    user    = users(:example_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = RegisteredElementPolicy.new(context, Usage)
    assert policy.index_template?
  end

  test "index_template?() respects role limits" do
    # sysadmin user limited to an insufficient role
    user    = users(:example_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::LOGGED_IN)
    policy  = RegisteredElementPolicy.new(context, Usage)
    assert !policy.index_template?
  end

  # new?()

  test "new?() returns false with a nil user" do
    context = RequestContext.new(user:        nil,
                                 institution: @element.institution)
    policy = RegisteredElementPolicy.new(context, @element)
    assert !policy.new?
  end

  test "new?() does not authorize non-privileged users" do
    user    = users(:southwest)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy = RegisteredElementPolicy.new(context, @element)
    assert !policy.new?
  end

  test "new?() authorizes institution administrators" do
    user = users(:southwest_admin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = RegisteredElementPolicy.new(context, @element)
    assert policy.new?
  end

  test "new?() does not authorize administrators of a different
  institution than in the request context" do
    user    = users(:southwest_admin)
    context = RequestContext.new(user:        user,
                                 institution: institutions(:northeast))
    policy  = RegisteredElementPolicy.new(context, @element)
    assert !policy.new?
  end

  test "new?() respects role limits" do
    # sysadmin user limited to an insufficient role
    user    = users(:southwest_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::LOGGED_IN)
    policy  = RegisteredElementPolicy.new(context, @element)
    assert !policy.new?
  end

  # show?()

  test "show?() returns false with a nil user" do
    context = RequestContext.new(user:        nil,
                                 institution: @element.institution)
    policy = RegisteredElementPolicy.new(context, @element)
    assert !policy.show?
  end

  test "show?() does not authorize an incorrect scope" do
    context = RequestContext.new(user:        users(:southwest_admin),
                                 institution: institutions(:northeast))
    policy  = RegisteredElementPolicy.new(context, @element)
    assert !policy.show?
  end

  test "show?() does not authorize users with no privileges" do
    user    = users(:southwest)
    context = RequestContext.new(user:        user,
                                 institution: @element.institution)
    policy  = RegisteredElementPolicy.new(context, @element)
    assert !policy.show?
  end

  test "show?() authorizes sysadmins" do
    user    = users(:southwest_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: @element.institution)
    policy  = RegisteredElementPolicy.new(context, @element)
    assert policy.show?
  end

  test "show?() authorizes administrators of the same institution" do
    user    = users(:southwest_admin)
    context = RequestContext.new(user:        user,
                                 institution: @element.institution)
    policy  = RegisteredElementPolicy.new(context, @element)
    assert policy.show?
  end

  test "show?() does not authorize administrators of a different institution
  than the request context" do
    user    = users(:southwest_admin)
    context = RequestContext.new(user:        user,
                                 institution: institutions(:northeast))
    policy  = RegisteredElementPolicy.new(context, @element)
    assert !policy.show?
  end

  test "show?() does not authorize administrators of a different institution
  than that of the element" do
    user    = users(:northeast_admin)
    context = RequestContext.new(user:        user,
                                 institution: institutions(:northeast))
    policy  = RegisteredElementPolicy.new(context, @element)
    assert !policy.show?
  end

  test "show?() respects role limits" do
    # sysadmin user limited to an insufficient role
    user    = users(:southwest_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::LOGGED_IN)
    policy  = RegisteredElementPolicy.new(context, @element)
    assert !policy.show?
  end

  # update?()

  test "update?() returns false with a nil user" do
    context = RequestContext.new(user:        nil,
                                 institution: @element.institution)
    policy = RegisteredElementPolicy.new(context, @element)
    assert !policy.update?
  end

  test "update?() does not authorize an incorrect scope" do
    context = RequestContext.new(user:        users(:southwest_admin),
                                 institution: institutions(:northeast))
    policy  = RegisteredElementPolicy.new(context, @element)
    assert !policy.update?
  end

  test "update?() does not authorize users with no privileges" do
    user    = users(:southwest)
    context = RequestContext.new(user:        user,
                                 institution: @element.institution)
    policy  = RegisteredElementPolicy.new(context, @element)
    assert !policy.update?
  end

  test "update?() authorizes sysadmins" do
    user    = users(:southwest_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: @element.institution)
    policy = RegisteredElementPolicy.new(context, @element)
    assert policy.update?
  end

  test "update?() authorizes administrators of the same institution" do
    user = users(:southwest_admin)
    context = RequestContext.new(user:        user,
                                 institution: @element.institution)
    policy  = RegisteredElementPolicy.new(context, @element)
    assert policy.update?
  end

  test "update?() does not authorize administrators of a different
  institution than the request context" do
    user    = users(:southwest_admin)
    context = RequestContext.new(user:        user,
                                 institution: institutions(:northeast))
    policy  = RegisteredElementPolicy.new(context, @element)
    assert !policy.update?
  end

  test "update?() does not authorize administrators of a different institution
  than that of the element" do
    user    = users(:northeast_admin)
    context = RequestContext.new(user:        user,
                                 institution: institutions(:northeast))
    policy  = RegisteredElementPolicy.new(context, @element)
    assert !policy.update?
  end

  test "update?() respects role limits" do
    # sysadmin user limited to an insufficient role
    user    = users(:southwest_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::LOGGED_IN)
    policy  = RegisteredElementPolicy.new(context, @element)
    assert !policy.update?
  end

end
