require 'test_helper'

class ItemPolicyTest < ActiveSupport::TestCase

  setup do
    @item = items(:item1)
  end

  # index?()

  test "index?() authorizes everyone" do
    policy = ItemPolicy.new(users(:norights), @item)
    assert policy.index?
  end

  # show?()

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

end
