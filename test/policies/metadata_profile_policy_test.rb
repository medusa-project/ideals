require 'test_helper'

class MetadataProfilePolicyTest < ActiveSupport::TestCase

  setup do
    @user    = users(:sally)
    @profile = metadata_profiles(:default)
  end

  # clone?()

  test "clone?() returns false with a nil user" do
    policy = MetadataProfilePolicy.new(nil, @profile)
    assert !policy.clone?
  end

  test "clone?() does not authorize non-sysadmins" do
    policy = MetadataProfilePolicy.new(users(:norights), @profile)
    assert !policy.clone?
  end

  test "clone?() authorizes sysadmins" do
    policy = MetadataProfilePolicy.new(users(:admin), @profile)
    assert policy.clone?
  end

  # create?()

  test "create?() returns false with a nil user" do
    policy = MetadataProfilePolicy.new(nil, @profile)
    assert !policy.create?
  end

  test "create?() does not authorize non-sysadmins" do
    policy = MetadataProfilePolicy.new(users(:norights), @profile)
    assert !policy.create?
  end

  test "create?() authorizes sysadmins" do
    policy = MetadataProfilePolicy.new(users(:admin), @profile)
    assert policy.create?
  end

  # destroy?()

  test "destroy?() returns false with a nil user" do
    policy = MetadataProfilePolicy.new(nil, @profile)
    assert !policy.destroy?
  end

  test "destroy?() does not authorize non-sysadmins" do
    policy = MetadataProfilePolicy.new(users(:norights), @profile)
    assert !policy.destroy?
  end

  test "destroy?() authorizes sysadmins" do
    policy = MetadataProfilePolicy.new(users(:admin), @profile)
    assert policy.destroy?
  end

  # edit?()

  test "edit?() returns false with a nil user" do
    policy = MetadataProfilePolicy.new(nil, @profile)
    assert !policy.edit?
  end

  test "edit?() does not authorize non-sysadmins" do
    policy = MetadataProfilePolicy.new(users(:norights), @profile)
    assert !policy.edit?
  end

  test "edit?() authorizes sysadmins" do
    policy = MetadataProfilePolicy.new(users(:admin), @profile)
    assert policy.edit?
  end

  # index?()

  test "index?() returns false with a nil user" do
    policy = MetadataProfilePolicy.new(nil, MetadataProfile)
    assert !policy.index?
  end

  test "index?() does not authorize non-sysadmins" do
    policy = MetadataProfilePolicy.new(users(:norights), MetadataProfile)
    assert !policy.index?
  end

  test "index?() authorizes sysadmins" do
    policy = MetadataProfilePolicy.new(users(:admin), MetadataProfile)
    assert policy.index?
  end

  # new()

  test "new?() returns false with a nil user" do
    policy = MetadataProfilePolicy.new(nil, @profile)
    assert !policy.new?
  end

  test "new?() does not authorize non-sysadmins" do
    policy = MetadataProfilePolicy.new(users(:norights), @profile)
    assert !policy.new?
  end

  test "new?() authorizes sysadmins" do
    policy = MetadataProfilePolicy.new(users(:admin), @profile)
    assert policy.new?
  end

  # show?()

  test "show?() returns false with a nil user" do
    policy = MetadataProfilePolicy.new(nil, @profile)
    assert !policy.show?
  end

  test "show?() does not authorize non-sysadmins" do
    policy = MetadataProfilePolicy.new(users(:norights), @profile)
    assert !policy.show?
  end

  test "show?() authorizes sysadmins" do
    policy = MetadataProfilePolicy.new(users(:admin), @profile)
    assert policy.show?
  end

  # update?()

  test "update?() returns false with a nil user" do
    policy = MetadataProfilePolicy.new(nil, @profile)
    assert !policy.update?
  end

  test "update?() does not authorize non-sysadmins" do
    policy = MetadataProfilePolicy.new(users(:norights), @profile)
    assert !policy.update?
  end

  test "update?() authorizes sysadmins" do
    policy = MetadataProfilePolicy.new(users(:admin), @profile)
    assert policy.update?
  end

end
