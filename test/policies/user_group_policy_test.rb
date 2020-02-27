require 'test_helper'

class UserGroupPolicyTest < ActiveSupport::TestCase

  setup do
    @user_group = user_groups(:one)
  end

  # create?()

  test "create?() authorizes managers of any collection" do
    subject_user = users(:norights)
    subject_user.managers.build(collection: collections(:collection1))
    subject_user.save!
    policy = UserGroupPolicy.new(subject_user, @user)
    assert policy.create?
  end

  test "create?() authorizes administrators of any unit" do
    subject_user = users(:norights)
    subject_user.administrators.build(unit: units(:unit1))
    subject_user.save!
    policy = UserGroupPolicy.new(subject_user, @user)
    assert policy.create?
  end

  test "create?() authorizes sysadmins" do
    policy = UserGroupPolicy.new(users(:admin), @user)
    assert policy.create?
  end

  test "create?() does not authorize anybody else" do
    policy = UserGroupPolicy.new(users(:norights), @user)
    assert !policy.create?
  end

  test "create?() returns false for a nil user" do
    policy = UserGroupPolicy.new(nil, @user)
    assert !policy.create?
  end

  # destroy?()

  test "destroy?() authorizes managers of any collection" do
    subject_user = users(:norights)
    subject_user.managers.build(collection: collections(:collection1))
    subject_user.save!
    policy = UserGroupPolicy.new(subject_user, @user)
    assert policy.destroy?
  end

  test "destroy?() authorizes administrators of any unit" do
    subject_user = users(:norights)
    subject_user.administrators.build(unit: units(:unit1))
    subject_user.save!
    policy = UserGroupPolicy.new(subject_user, @user)
    assert policy.destroy?
  end

  test "destroy?() authorizes sysadmins" do
    policy = UserGroupPolicy.new(users(:admin), @user)
    assert policy.destroy?
  end

  test "destroy?() does not authorize anybody else" do
    policy = UserGroupPolicy.new(users(:norights), @user)
    assert !policy.destroy?
  end

  test "destroy?() returns false for a nil user" do
    policy = UserGroupPolicy.new(nil, @user)
    assert !policy.destroy?
  end

  # edit?()

  test "edit?() authorizes managers of any collection" do
    subject_user = users(:norights)
    subject_user.managers.build(collection: collections(:collection1))
    subject_user.save!
    policy = UserGroupPolicy.new(subject_user, @user)
    assert policy.edit?
  end

  test "edit?() authorizes administrators of any unit" do
    subject_user = users(:norights)
    subject_user.administrators.build(unit: units(:unit1))
    subject_user.save!
    policy = UserGroupPolicy.new(subject_user, @user)
    assert policy.edit?
  end

  test "edit?() authorizes sysadmins" do
    policy = UserGroupPolicy.new(users(:admin), @user)
    assert policy.edit?
  end

  test "edit?() does not authorize anybody else" do
    policy = UserGroupPolicy.new(users(:norights), @user)
    assert !policy.edit?
  end

  test "edit?() returns false for a nil user" do
    policy = UserGroupPolicy.new(nil, @user)
    assert !policy.edit?
  end

  # index?()

  test "index?() authorizes managers of any collection" do
    subject_user = users(:norights)
    subject_user.managers.build(collection: collections(:collection1))
    subject_user.save!
    policy = UserGroupPolicy.new(subject_user, @user)
    assert policy.index?
  end

  test "index?() authorizes administrators of any unit" do
    subject_user = users(:norights)
    subject_user.administrators.build(unit: units(:unit1))
    subject_user.save!
    policy = UserGroupPolicy.new(subject_user, @user)
    assert policy.index?
  end

  test "index?() authorizes sysadmins" do
    policy = UserGroupPolicy.new(users(:admin), @user)
    assert policy.index?
  end

  test "index?() does not authorize anybody else" do
    policy = UserGroupPolicy.new(users(:norights), @user)
    assert !policy.index?
  end

  test "index?() returns false for a nil user" do
    policy = UserGroupPolicy.new(nil, @user)
    assert !policy.index?
  end

  # new()

  test "new?() authorizes managers of any collection" do
    subject_user = users(:norights)
    subject_user.managers.build(collection: collections(:collection1))
    subject_user.save!
    policy = UserGroupPolicy.new(subject_user, @user)
    assert policy.new?
  end

  test "new?() authorizes administrators of any unit" do
    subject_user = users(:norights)
    subject_user.administrators.build(unit: units(:unit1))
    subject_user.save!
    policy = UserGroupPolicy.new(subject_user, @user)
    assert policy.new?
  end

  test "new?() authorizes sysadmins" do
    policy = UserGroupPolicy.new(users(:admin), @user)
    assert policy.new?
  end

  test "new?() does not authorize anybody else" do
    policy = UserGroupPolicy.new(users(:norights), @user)
    assert !policy.new?
  end

  test "new?() returns false for a nil user" do
    policy = UserGroupPolicy.new(nil, @user)
    assert !policy.new?
  end

  # show?()

  test "show?() authorizes managers of any collection" do
    subject_user = users(:norights)
    subject_user.managers.build(collection: collections(:collection1))
    subject_user.save!
    policy = UserGroupPolicy.new(subject_user, @user)
    assert policy.show?
  end

  test "show?() authorizes administrators of any unit" do
    subject_user = users(:norights)
    subject_user.administrators.build(unit: units(:unit1))
    subject_user.save!
    policy = UserGroupPolicy.new(subject_user, @user)
    assert policy.show?
  end

  test "show?() authorizes sysadmins" do
    policy = UserGroupPolicy.new(users(:admin), @user)
    assert policy.show?
  end

  test "show?() does not authorize anybody else" do
    policy = UserGroupPolicy.new(users(:norights), @user)
    assert !policy.show?
  end

  test "show?() returns false for a nil user" do
    policy = UserGroupPolicy.new(nil, @user)
    assert !policy.show?
  end

  # update?()

  test "update?() authorizes managers of any collection" do
    subject_user = users(:norights)
    subject_user.managers.build(collection: collections(:collection1))
    subject_user.save!
    policy = UserGroupPolicy.new(subject_user, @user)
    assert policy.update?
  end

  test "update?() authorizes administrators of any unit" do
    subject_user = users(:norights)
    subject_user.administrators.build(unit: units(:unit1))
    subject_user.save!
    policy = UserGroupPolicy.new(subject_user, @user)
    assert policy.update?
  end

  test "update?() authorizes sysadmins" do
    policy = UserGroupPolicy.new(users(:admin), @user)
    assert policy.update?
  end

  test "update?() does not authorize anybody else" do
    policy = UserGroupPolicy.new(users(:norights), @user)
    assert !policy.update?
  end

  test "update?() returns false for a nil user" do
    policy = UserGroupPolicy.new(nil, @user)
    assert !policy.update?
  end

end
