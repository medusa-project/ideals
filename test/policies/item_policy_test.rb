require 'test_helper'

class ItemPolicyTest < ActiveSupport::TestCase

  class ScopeTest < ActiveSupport::TestCase

    test "resolve() sets no filters for sysadmins" do
      relation = ItemRelation.new
      scope = ItemPolicy::Scope.new(users(:admin), relation)
      assert_equal 0, scope.resolve.instance_variable_get("@filters").length
    end

    test "resolve() sets filters for non-sysadmins" do
      relation = ItemRelation.new
      scope = ItemPolicy::Scope.new(users(:norights), relation)
      assert_equal [
                       [Item::IndexFields::DISCOVERABLE, true],
                       [Item::IndexFields::IN_ARCHIVE, true],
                       [Item::IndexFields::WITHDRAWN, false]
                   ],
                   scope.resolve.instance_variable_get("@filters")
    end

  end

  setup do
    @item = items(:item1)
  end

  # destroy?()

  test "destroy?() returns false with a nil user" do
    policy = ItemPolicy.new(nil, @item)
    assert !policy.destroy?
  end

  test "destroy?() is restrictive by default" do
    policy = ItemPolicy.new(users(:norights), @item)
    assert !policy.destroy?
  end

  test "destroy?() authorizes sysadmins" do
    policy = ItemPolicy.new(users(:admin), @item)
    assert policy.destroy?
  end

  # edit_properties?()

  test "edit_properties?() returns false with a nil user" do
    policy = ItemPolicy.new(nil, @item)
    assert !policy.edit_properties?
  end

  test "edit_properties?() is restrictive by default" do
    policy = ItemPolicy.new(users(:norights), @item)
    assert !policy.edit_properties?
  end

  test "edit_properties?() authorizes sysadmins" do
    policy = ItemPolicy.new(users(:admin), @item)
    assert policy.edit_properties?
  end

  test "edit_properties?() authorizes unit admins" do
    user = users(:norights)
    unit = @item.primary_collection.units.first
    unit.administrators.build(user: user)
    unit.save!
    policy = ItemPolicy.new(user, @item)
    assert policy.edit_properties?
  end

  test "edit_properties?() authorizes collection managers" do
    user = users(:norights)
    collection = @item.primary_collection
    collection.managers.build(user: user)
    collection.save!
    policy = ItemPolicy.new(user, @item)
    assert policy.edit_properties?
  end

  # index?()

  test "index?() returns true with a nil user" do
    policy = ItemPolicy.new(nil, Item)
    assert policy.index?
  end

  test "index?() authorizes everyone" do
    policy = ItemPolicy.new(users(:norights), Item)
    assert policy.index?
  end

  # show?()

  test "show?() returns true with a nil user" do
    policy = ItemPolicy.new(nil, @item)
    assert policy.show?
  end

  test "show?() restricts undiscoverable items by default" do
    policy = ItemPolicy.new(users(:norights), items(:undiscoverable))
    assert !policy.show?
  end

  test "show?() restricts not-in-archive items by default" do
    policy = ItemPolicy.new(users(:norights), items(:not_in_archive))
    assert !policy.show?
  end

  test "show?() restricts withdrawn items by default" do
    policy = ItemPolicy.new(users(:norights), items(:withdrawn))
    assert !policy.show?
  end

  test "show?() authorizes sysadmins to undiscoverable items" do
    policy = ItemPolicy.new(users(:admin), items(:undiscoverable))
    assert policy.show?
  end

  test "show?() authorizes sysadmins to not-in-archive items" do
    policy = ItemPolicy.new(users(:admin), items(:not_in_archive))
    assert policy.show?
  end

  test "show?() authorizes sysadmins to withdrawn items" do
    policy = ItemPolicy.new(users(:admin), items(:withdrawn))
    assert policy.show?
  end

  # update?()

  test "update?() returns false with a nil user" do
    policy = ItemPolicy.new(nil, @item)
    assert !policy.update?
  end

  test "update?() is restrictive by default" do
    policy = ItemPolicy.new(users(:norights), @item)
    assert !policy.update?
  end

  test "update?() authorizes sysadmins" do
    policy = ItemPolicy.new(users(:admin), @item)
    assert policy.update?
  end

  test "update?() authorizes unit admins" do
    user = users(:norights)
    unit = @item.primary_collection.units.first
    unit.administrators.build(user: user)
    unit.save!
    policy = ItemPolicy.new(user, @item)
    assert policy.update?
  end

  test "update?() authorizes collection managers" do
    user = users(:norights)
    collection = @item.primary_collection
    collection.managers.build(user: user)
    collection.save!
    policy = ItemPolicy.new(user, @item)
    assert policy.update?
  end

end
