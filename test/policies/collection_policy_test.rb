require 'test_helper'

class CollectionPolicyTest < ActiveSupport::TestCase

  setup do
    @collection = collections(:collection1)
  end

  # create?()

  test "create?() returns false with a nil user" do
    policy = CollectionPolicy.new(nil, @collection)
    assert !policy.create?
  end

  test "create?() is restrictive by default" do
    policy = CollectionPolicy.new(users(:norights), @collection)
    assert !policy.create?
  end

  test "create?() authorizes sysadmins" do
    policy = CollectionPolicy.new(users(:admin), @collection)
    assert policy.create?
  end

  test "create?() authorizes unit admins" do
    user = users(:norights)
    unit = @collection.units.first
    unit.administrators.build(user: user)
    unit.save!
    policy = CollectionPolicy.new(user, @collection)
    assert policy.create?
  end

  test "create?() authorizes collection managers" do
    user = users(:norights)
    @collection.managing_users << user
    @collection.save!
    policy = CollectionPolicy.new(user, @collection)
    assert policy.create?
  end

  # destroy?()

  test "destroy?() returns false with a nil user" do
    policy = CollectionPolicy.new(nil, @collection)
    assert !policy.destroy?
  end

  test "destroy?() is restrictive by default" do
    policy = CollectionPolicy.new(users(:norights), @collection)
    assert !policy.destroy?
  end

  test "destroy?() authorizes sysadmins" do
    policy = CollectionPolicy.new(users(:admin), @collection)
    assert policy.destroy?
  end

  # edit_access?()

  test "edit_access?() returns false with a nil user" do
    policy = CollectionPolicy.new(nil, @collection)
    assert !policy.edit_access?
  end

  test "edit_access?() is restrictive by default" do
    policy = CollectionPolicy.new(users(:norights), @collection)
    assert !policy.edit_access?
  end

  test "edit_access?() authorizes sysadmins" do
    policy = CollectionPolicy.new(users(:admin), @collection)
    assert policy.edit_access?
  end

  # edit_membership?()

  test "edit_membership?() returns false with a nil user" do
    policy = CollectionPolicy.new(nil, @collection)
    assert !policy.edit_membership?
  end

  test "edit_membership?() is restrictive by default" do
    policy = CollectionPolicy.new(users(:norights), @collection)
    assert !policy.edit_membership?
  end

  test "edit_membership?() authorizes sysadmins" do
    policy = CollectionPolicy.new(users(:admin), @collection)
    assert policy.edit_membership?
  end

  # edit_properties?()

  test "edit_properties?() returns false with a nil user" do
    policy = CollectionPolicy.new(nil, @collection)
    assert !policy.edit_properties?
  end

  test "edit_properties?() is restrictive by default" do
    policy = CollectionPolicy.new(users(:norights), @collection)
    assert !policy.edit_properties?
  end

  test "edit_properties?() authorizes sysadmins" do
    policy = CollectionPolicy.new(users(:admin), @collection)
    assert policy.edit_properties?
  end

  # index?()

  test "index?() returns true with a nil user" do
    policy = CollectionPolicy.new(nil, Collection)
    assert policy.index?
  end

  test "index?() authorizes everyone" do
    policy = CollectionPolicy.new(users(:norights), Collection)
    assert policy.index?
  end

  # new?()

  test "new?() returns false with a nil user" do
    policy = CollectionPolicy.new(nil, @collection)
    assert !policy.new?
  end

  test "new?() is restrictive by default" do
    policy = CollectionPolicy.new(users(:norights), @collection)
    assert !policy.new?
  end

  test "new?() authorizes sysadmins" do
    policy = CollectionPolicy.new(users(:admin), @collection)
    assert policy.new?
  end

  # show?()

  test "show?() returns true with a nil user" do
    policy = CollectionPolicy.new(nil, @collection)
    assert policy.show?
  end

  test "show?() authorizes everyone" do
    policy = CollectionPolicy.new(users(:norights), @collection)
    assert policy.show?
  end

  # submit_item?()

  test "submit_item?() returns false with a nil user" do
    policy = CollectionPolicy.new(nil, @collection)
    assert !policy.submit_item?
  end

  test "submit_item?() is restrictive by default" do
    policy = CollectionPolicy.new(users(:norights), @collection)
    assert !policy.submit_item?
  end

  test "submit_item?() authorizes sysadmins" do
    policy = CollectionPolicy.new(users(:admin), @collection)
    assert policy.submit_item?
  end

  test "submit_item?() authorizes unit admins" do
    user = users(:norights)
    unit = @collection.units.first
    unit.administrators.build(user: user)
    unit.save!
    policy = CollectionPolicy.new(user, @collection)
    assert policy.submit_item?
  end

  test "submit_item?() authorizes collection managers" do
    user = users(:norights)
    @collection.managing_users << user
    @collection.save!
    policy = CollectionPolicy.new(user, @collection)
    assert policy.submit_item?
  end

  test "submit_item?() authorizes collection submitters" do
    user = users(:norights)
    @collection.submitting_users << user
    @collection.save!
    policy = CollectionPolicy.new(user, @collection)
    assert policy.submit_item?
  end

  # update?()

  test "update?() returns false with a nil user" do
    policy = CollectionPolicy.new(nil, @collection)
    assert !policy.update?
  end

  test "update?() is restrictive by default" do
    policy = CollectionPolicy.new(users(:norights), @collection)
    assert !policy.update?
  end

  test "update?() authorizes sysadmins" do
    policy = CollectionPolicy.new(users(:admin), @collection)
    assert policy.update?
  end

  test "update?() authorizes unit admins" do
    user = users(:norights)
    unit = @collection.units.first
    unit.administrators.build(user: user)
    unit.save!
    policy = CollectionPolicy.new(user, @collection)
    assert policy.update?
  end

  test "update?() authorizes collection managers" do
    user = users(:norights)
    @collection.managing_users << user
    @collection.save!
    policy = CollectionPolicy.new(user, @collection)
    assert policy.update?
  end

end
