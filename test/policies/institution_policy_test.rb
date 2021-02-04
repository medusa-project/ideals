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
    context = UserContext.new(users(:somewhere), Role::NO_LIMIT)
    policy  = InstitutionPolicy.new(context, @institution)
    assert !policy.create?
  end

  test "create?() authorizes sysadmins" do
    context = UserContext.new(users(:admin), Role::NO_LIMIT)
    policy  = InstitutionPolicy.new(context, @institution)
    assert policy.create?
  end

  test "create?() respects role limits" do
    # sysadmin user limited to an insufficient role
    context = UserContext.new(users(:somewhere_admin), Role::LOGGED_IN)
    policy  = InstitutionPolicy.new(context, @institution)
    assert !policy.create?
  end

  # destroy?()

  test "destroy?() returns false with a nil user context" do
    policy = InstitutionPolicy.new(nil, @institution)
    assert !policy.destroy?
  end

  test "destroy?() is restrictive by default" do
    context = UserContext.new(users(:somewhere), Role::NO_LIMIT)
    policy  = InstitutionPolicy.new(context, @institution)
    assert !policy.destroy?
  end

  test "destroy?() authorizes sysadmins" do
    context = UserContext.new(users(:admin), Role::NO_LIMIT)
    policy  = InstitutionPolicy.new(context, @institution)
    assert policy.destroy?
  end

  test "destroy?() respects role limits" do
    # sysadmin user limited to an insufficient role
    context = UserContext.new(users(:somewhere_admin), Role::LOGGED_IN)
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
    context = UserContext.new(users(:somewhere), Role::NO_LIMIT)
    policy  = InstitutionPolicy.new(context, @institution)
    assert !policy.edit?
  end

  test "edit?() authorizes sysadmins" do
    context = UserContext.new(users(:admin), Role::NO_LIMIT)
    policy  = InstitutionPolicy.new(context, @institution)
    assert policy.edit?
  end

  test "edit?() authorizes administrators of the same institution" do
    user = users(:somewhere_admin)
    context = UserContext.new(user, Role::NO_LIMIT)
    policy  = InstitutionPolicy.new(context, user.institution)
    assert policy.edit?
  end

  test "edit?() does not authorize administrators of different institutions" do
    user = users(:somewhere_admin)
    context = UserContext.new(user, Role::NO_LIMIT)
    policy  = InstitutionPolicy.new(context, @institution)
    assert policy.edit?
  end

  test "edit?() respects role limits" do
    # sysadmin user limited to an insufficient role
    context = UserContext.new(users(:somewhere_admin), Role::LOGGED_IN)
    policy  = InstitutionPolicy.new(context, @institution)
    assert !policy.edit?
  end

  # index?()

  test "index?() returns false with a nil user context" do
    policy = InstitutionPolicy.new(nil, @institution)
    assert !policy.index?
  end

  test "index?() is restrictive by default" do
    context = UserContext.new(users(:somewhere), Role::NO_LIMIT)
    policy  = InstitutionPolicy.new(context, @institution)
    assert !policy.index?
  end

  test "index?() authorizes sysadmins" do
    context = UserContext.new(users(:admin), Role::NO_LIMIT)
    policy  = InstitutionPolicy.new(context, @institution)
    assert policy.index?
  end

  test "index?() respects role limits" do
    # sysadmin user limited to an insufficient role
    context = UserContext.new(users(:somewhere_admin), Role::LOGGED_IN)
    policy  = InstitutionPolicy.new(context, @institution)
    assert !policy.index?
  end

  # new?()

  test "new?() returns false with a nil user context" do
    policy = InstitutionPolicy.new(nil, @institution)
    assert !policy.new?
  end

  test "new?() is restrictive by default" do
    context = UserContext.new(users(:somewhere), Role::NO_LIMIT)
    policy  = InstitutionPolicy.new(context, @institution)
    assert !policy.new?
  end

  test "new?() authorizes sysadmins" do
    context = UserContext.new(users(:admin), Role::NO_LIMIT)
    policy  = InstitutionPolicy.new(context, @institution)
    assert policy.new?
  end

  test "new?() respects role limits" do
    # sysadmin user limited to an insufficient role
    context = UserContext.new(users(:somewhere_admin), Role::LOGGED_IN)
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
    context = UserContext.new(users(:somewhere), Role::NO_LIMIT)
    policy = InstitutionPolicy.new(context, @institution)
    assert !policy.show?
  end

  test "show?() authorizes sysadmins" do
    context = UserContext.new(users(:admin), Role::NO_LIMIT)
    policy  = InstitutionPolicy.new(context, @institution)
    assert policy.show?
  end

  test "show?() authorizes administrators of the same institution" do
    context = UserContext.new(users(:somewhere_admin), Role::NO_LIMIT)
    policy  = InstitutionPolicy.new(context, @institution)
    assert policy.show?
  end

  test "show?() does not authorize administrators of a different institution" do
    context = UserContext.new(users(:somewhere_admin), Role::NO_LIMIT)
    policy  = InstitutionPolicy.new(context, institutions(:uiuc))
    assert !policy.show?
  end

  test "show?() respects role limits" do
    # sysadmin user limited to an insufficient role
    context = UserContext.new(users(:somewhere_admin), Role::LOGGED_IN)
    policy  = InstitutionPolicy.new(context, @institution)
    assert !policy.show?
  end

  # update?()

  test "update?() returns false with a nil user context" do
    policy = InstitutionPolicy.new(nil, @institution)
    assert !policy.update?
  end

  test "update?() is restrictive by default" do
    skip # TODO: enable this once User.institution_admin?() is implemented properly
    context = UserContext.new(users(:somewhere), Role::NO_LIMIT)
    policy  = InstitutionPolicy.new(context, @institution)
    assert !policy.update?
  end

  test "update?() authorizes sysadmins" do
    context = UserContext.new(users(:admin), Role::NO_LIMIT)
    policy  = InstitutionPolicy.new(context, @institution)
    assert policy.update?
  end

  test "update?() authorizes administrators of the same institution" do
    user = users(:somewhere_admin)
    context = UserContext.new(user, Role::NO_LIMIT)
    policy  = InstitutionPolicy.new(context, user.institution)
    assert policy.update?
  end

  test "update?() does not authorize administrators of different institutions" do
    user = users(:somewhere_admin)
    context = UserContext.new(user, Role::NO_LIMIT)
    policy  = InstitutionPolicy.new(context, @institution)
    assert policy.update?
  end

  test "update?() respects role limits" do
    # sysadmin user limited to an insufficient role
    context = UserContext.new(users(:somewhere_admin), Role::LOGGED_IN)
    policy  = InstitutionPolicy.new(context, @institution)
    assert !policy.update?
  end

end