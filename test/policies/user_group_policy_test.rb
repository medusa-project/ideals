require 'test_helper'

class UserGroupPolicyTest < ActiveSupport::TestCase

  setup do
    @user_group = user_groups(:one)
  end

  # create?()

  test "create?() returns false with a nil user" do
    policy = UserGroupPolicy.new(nil, @user_group)
    assert !policy.create?
  end

  test "create?() authorizes managers of any collection" do
    subject_user = users(:norights)
    subject_user.managers.build(collection: collections(:collection1))
    subject_user.save!
    context = UserContext.new(subject_user, Role::NO_LIMIT)
    policy  = UserGroupPolicy.new(context, @user_group)
    assert policy.create?
  end

  test "create?() authorizes administrators of any unit" do
    subject_user = users(:norights)
    subject_user.administrators.build(unit: units(:unit1))
    subject_user.save!
    context = UserContext.new(subject_user, Role::NO_LIMIT)
    policy  = UserGroupPolicy.new(context, @user_group)
    assert policy.create?
  end

  test "create?() authorizes sysadmins" do
    context = UserContext.new(users(:admin), Role::NO_LIMIT)
    policy  = UserGroupPolicy.new(context, @user_group)
    assert policy.create?
  end

  test "create?() does not authorize anybody else" do
    context = UserContext.new(users(:norights), Role::NO_LIMIT)
    policy  = UserGroupPolicy.new(context, @user_group)
    assert !policy.create?
  end

  test "create?() respects role limits" do
    # sysadmin user limited to an insufficient role
    context = UserContext.new(users(:admin), Role::LOGGED_IN)
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
    subject_user.managers.build(collection: collections(:collection1))
    subject_user.save!
    context = UserContext.new(subject_user, Role::NO_LIMIT)
    policy  = UserGroupPolicy.new(context, @user_group)
    assert policy.destroy?
  end

  test "destroy?() authorizes administrators of any unit" do
    subject_user = users(:norights)
    subject_user.administrators.build(unit: units(:unit1))
    subject_user.save!
    context = UserContext.new(subject_user, Role::NO_LIMIT)
    policy  = UserGroupPolicy.new(context, @user_group)
    assert policy.destroy?
  end

  test "destroy?() authorizes sysadmins" do
    context = UserContext.new(users(:admin), Role::NO_LIMIT)
    policy  = UserGroupPolicy.new(context, @user_group)
    assert policy.destroy?
  end

  test "destroy?() does not authorize anybody else" do
    context = UserContext.new(users(:norights), Role::NO_LIMIT)
    policy  = UserGroupPolicy.new(context, @user_group)
    assert !policy.destroy?
  end

  test "destroy?() respects role limits" do
    # sysadmin user limited to an insufficient role
    context = UserContext.new(users(:admin), Role::LOGGED_IN)
    policy  = UserGroupPolicy.new(context, @user_group)
    assert !policy.destroy?
  end

  # edit?()

  test "edit?() returns false with a nil user" do
    policy = UserGroupPolicy.new(nil, @user_group)
    assert !policy.edit?
  end

  test "edit?() authorizes managers of any collection" do
    subject_user = users(:norights)
    subject_user.managers.build(collection: collections(:collection1))
    subject_user.save!
    context = UserContext.new(subject_user, Role::NO_LIMIT)
    policy  = UserGroupPolicy.new(context, @user_group)
    assert policy.edit?
  end

  test "edit?() authorizes administrators of any unit" do
    subject_user = users(:norights)
    subject_user.administrators.build(unit: units(:unit1))
    subject_user.save!
    context = UserContext.new(subject_user, Role::NO_LIMIT)
    policy  = UserGroupPolicy.new(context, @user_group)
    assert policy.edit?
  end

  test "edit?() authorizes sysadmins" do
    context = UserContext.new(users(:admin), Role::NO_LIMIT)
    policy = UserGroupPolicy.new(context, @user_group)
    assert policy.edit?
  end

  test "edit?() does not authorize anybody else" do
    context = UserContext.new(users(:norights), Role::NO_LIMIT)
    policy = UserGroupPolicy.new(context, @user_group)
    assert !policy.edit?
  end

  test "edit?() respects role limits" do
    # sysadmin user limited to an insufficient role
    context = UserContext.new(users(:admin), Role::LOGGED_IN)
    policy  = UserGroupPolicy.new(context, @user_group)
    assert !policy.edit?
  end

  # index?()

  test "index?() returns false with a nil user" do
    policy = UserGroupPolicy.new(nil, UserGroup)
    assert !policy.index?
  end

  test "index?() authorizes managers of any collection" do
    subject_user = users(:norights)
    subject_user.managers.build(collection: collections(:collection1))
    subject_user.save!
    context = UserContext.new(subject_user, Role::NO_LIMIT)
    policy  = UserGroupPolicy.new(context, UserGroup)
    assert policy.index?
  end

  test "index?() authorizes administrators of any unit" do
    subject_user = users(:norights)
    subject_user.administrators.build(unit: units(:unit1))
    subject_user.save!
    context = UserContext.new(subject_user, Role::NO_LIMIT)
    policy  = UserGroupPolicy.new(context, UserGroup)
    assert policy.index?
  end

  test "index?() authorizes sysadmins" do
    context = UserContext.new(users(:admin), Role::NO_LIMIT)
    policy = UserGroupPolicy.new(context, UserGroup)
    assert policy.index?
  end

  test "index?() does not authorize anybody else" do
    context = UserContext.new(users(:norights), Role::NO_LIMIT)
    policy = UserGroupPolicy.new(context, UserGroup)
    assert !policy.index?
  end

  test "index?() respects role limits" do
    # sysadmin user limited to an insufficient role
    context = UserContext.new(users(:admin), Role::LOGGED_IN)
    policy  = UserGroupPolicy.new(context, @user_group)
    assert !policy.index?
  end

  # new()

  test "new?() returns false with a nil user" do
    policy = UserGroupPolicy.new(nil, @user_group)
    assert !policy.new?
  end

  test "new?() authorizes managers of any collection" do
    subject_user = users(:norights)
    subject_user.managers.build(collection: collections(:collection1))
    subject_user.save!
    context = UserContext.new(subject_user, Role::NO_LIMIT)
    policy  = UserGroupPolicy.new(context, @user_group)
    assert policy.new?
  end

  test "new?() authorizes administrators of any unit" do
    subject_user = users(:norights)
    subject_user.administrators.build(unit: units(:unit1))
    subject_user.save!
    context = UserContext.new(subject_user, Role::NO_LIMIT)
    policy  = UserGroupPolicy.new(context, @user_group)
    assert policy.new?
  end

  test "new?() authorizes sysadmins" do
    context = UserContext.new(users(:admin), Role::NO_LIMIT)
    policy = UserGroupPolicy.new(context, @user_group)
    assert policy.new?
  end

  test "new?() does not authorize anybody else" do
    context = UserContext.new(users(:norights), Role::NO_LIMIT)
    policy  = UserGroupPolicy.new(context, @user_group)
    assert !policy.new?
  end

  test "new?() respects role limits" do
    # sysadmin user limited to an insufficient role
    context = UserContext.new(users(:admin), Role::LOGGED_IN)
    policy  = UserGroupPolicy.new(context, @user_group)
    assert !policy.new?
  end

  # show?()

  test "show?() returns false with a nil user" do
    policy = UserGroupPolicy.new(nil, @user_group)
    assert !policy.show?
  end

  test "show?() authorizes managers of any collection" do
    subject_user = users(:norights)
    subject_user.managers.build(collection: collections(:collection1))
    subject_user.save!
    context = UserContext.new(subject_user, Role::NO_LIMIT)
    policy  = UserGroupPolicy.new(context, @user_group)
    assert policy.show?
  end

  test "show?() authorizes administrators of any unit" do
    subject_user = users(:norights)
    subject_user.administrators.build(unit: units(:unit1))
    subject_user.save!
    context = UserContext.new(subject_user, Role::NO_LIMIT)
    policy  = UserGroupPolicy.new(context, @user_group)
    assert policy.show?
  end

  test "show?() authorizes sysadmins" do
    context = UserContext.new(users(:admin), Role::NO_LIMIT)
    policy = UserGroupPolicy.new(context, @user_group)
    assert policy.show?
  end

  test "show?() does not authorize anybody else" do
    context = UserContext.new(users(:norights), Role::NO_LIMIT)
    policy = UserGroupPolicy.new(context, @user_group)
    assert !policy.show?
  end

  test "show?() respects role limits" do
    # sysadmin user limited to an insufficient role
    context = UserContext.new(users(:admin), Role::LOGGED_IN)
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
    subject_user.managers.build(collection: collections(:collection1))
    subject_user.save!
    context = UserContext.new(subject_user, Role::NO_LIMIT)
    policy  = UserGroupPolicy.new(context, @user_group)
    assert policy.update?
  end

  test "update?() authorizes administrators of any unit" do
    subject_user = users(:norights)
    subject_user.administrators.build(unit: units(:unit1))
    subject_user.save!
    context = UserContext.new(subject_user, Role::NO_LIMIT)
    policy  = UserGroupPolicy.new(context, @user_group)
    assert policy.update?
  end

  test "update?() authorizes sysadmins" do
    context = UserContext.new(users(:admin), Role::NO_LIMIT)
    policy = UserGroupPolicy.new(context, @user_group)
    assert policy.update?
  end

  test "update?() does not authorize anybody else" do
    context = UserContext.new(users(:norights), Role::NO_LIMIT)
    policy = UserGroupPolicy.new(context, @user_group)
    assert !policy.update?
  end

  test "update?() respects role limits" do
    # sysadmin user limited to an insufficient role
    context = UserContext.new(users(:admin), Role::LOGGED_IN)
    policy  = UserGroupPolicy.new(context, @user_group)
    assert !policy.update?
  end

end
