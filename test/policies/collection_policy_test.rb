require 'test_helper'

class CollectionPolicyTest < ActiveSupport::TestCase

  setup do
    @collection = collections(:collection1)
  end

  # create?()

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

  # destroy?()

  test "destroy?() is restrictive by default" do
    policy = CollectionPolicy.new(users(:norights), @collection)
    assert !policy.destroy?
  end

  test "destroy?() authorizes sysadmins" do
    policy = CollectionPolicy.new(users(:admin), @collection)
    assert policy.destroy?
  end

  # edit?()

  test "edit?() is restrictive by default" do
    policy = CollectionPolicy.new(users(:norights), @collection)
    assert !policy.edit?
  end

  test "edit?() authorizes sysadmins" do
    policy = CollectionPolicy.new(users(:admin), @collection)
    assert policy.edit?
  end

  # index?()

  test "index?() authorizes everyone" do
    policy = CollectionPolicy.new(users(:norights), @collection)
    assert policy.index?
  end

  # new?()

  test "new?() is restrictive by default" do
    policy = CollectionPolicy.new(users(:norights), @collection)
    assert !policy.new?
  end

  test "new?() authorizes sysadmins" do
    policy = CollectionPolicy.new(users(:admin), @collection)
    assert policy.new?
  end

  # show?()

  test "show?() authorizes everyone" do
    policy = CollectionPolicy.new(users(:norights), @collection)
    assert policy.show?
  end

  # update?()

  test "update?() is restrictive by default" do
    policy = CollectionPolicy.new(users(:norights), @collection)
    assert !policy.update?
  end

  test "update?() authorizes sysadmins" do
    policy = CollectionPolicy.new(users(:admin), @collection)
    assert policy.new?
  end

end
