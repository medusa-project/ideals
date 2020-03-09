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

  # cancel_submission?()

  test "cancel_submission?() returns false with a nil user" do
    policy = ItemPolicy.new(nil, @item)
    assert !policy.cancel_submission?
  end

  test "cancel_submission?() does not authorize non-sysadmins" do
    policy = ItemPolicy.new(users(:norights), @item)
    assert !policy.cancel_submission?
  end

  test "cancel_submission?() authorizes sysadmins" do
    policy = ItemPolicy.new(users(:admin), @item)
    assert policy.cancel_submission?
  end

  test "cancel_submission?() authorizes the submission owner if the item is not in archive" do
    user = users(:norights)
    @item.submitter = user
    @item.in_archive = false
    policy = ItemPolicy.new(user, @item)
    assert policy.cancel_submission?
  end

  test "cancel_submission?() does not authorize the submission owner if the item is in archive" do
    user = users(:norights)
    @item.submitter = user
    @item.in_archive = true
    policy = ItemPolicy.new(user, @item)
    assert !policy.cancel_submission?
  end

  test "cancel_submission?() authorizes managers of the submission's collection" do
    doing_user = users(:norights)
    collection = collections(:collection1)
    collection.managing_users << doing_user
    collection.save!
    @item.submitter          = users(:sally) # somebody else
    @item.primary_collection = collection

    policy = ItemPolicy.new(doing_user, @item)
    assert policy.cancel_submission?
  end

  test "cancel_submission?() authorizes admins of the submission's collection's unit" do
    doing_user               = users(:norights)
    collection               = collections(:collection1)
    unit                     = collection.primary_unit
    unit.administering_users << doing_user
    unit.save!
    @item.submitter          = users(:sally) # somebody else
    @item.primary_collection = collection

    policy = ItemPolicy.new(doing_user, @item)
    assert policy.cancel_submission?
  end

  test "cancel_submission?() does not authorize anyone else" do
    policy = ItemPolicy.new(users(:norights), @item)
    assert !policy.cancel_submission?
  end

  # deposit?()

  test "deposit?() returns false with a nil user" do
    policy = ItemPolicy.new(nil, @item)
    assert !policy.deposit?
  end

  test "deposit?() authorizes logged-in users" do
    policy = ItemPolicy.new(users(:norights), @item)
    assert policy.deposit?
  end


  # destroy?()

  test "destroy?() returns false with a nil user" do
    policy = ItemPolicy.new(nil, @item)
    assert !policy.destroy?
  end

  test "destroy?() does not authorize non-sysadmins" do
    policy = ItemPolicy.new(users(:norights), @item)
    assert !policy.destroy?
  end

  test "destroy?() authorizes sysadmins" do
    policy = ItemPolicy.new(users(:admin), @item)
    assert policy.destroy?
  end

  test "destroy?() authorizes the submission owner if the item is not in archive" do
    user = users(:norights)
    @item.submitter = user
    @item.in_archive = false
    policy = ItemPolicy.new(user, @item)
    assert policy.destroy?
  end

  test "destroy?() does not authorize the submission owner if the item is in archive" do
    user = users(:norights)
    @item.submitter = user
    @item.in_archive = true
    policy = ItemPolicy.new(user, @item)
    assert !policy.destroy?
  end

  test "destroy?() authorizes managers of the submission's collection" do
    doing_user = users(:norights)
    collection = collections(:collection1)
    collection.managing_users << doing_user
    collection.save!
    @item.submitter          = users(:sally) # somebody else
    @item.primary_collection = collection

    policy = ItemPolicy.new(doing_user, @item)
    assert policy.destroy?
  end

  test "destroy?() authorizes admins of the submission's collection's unit" do
    doing_user               = users(:norights)
    collection               = collections(:collection1)
    unit                     = collection.primary_unit
    unit.administering_users << doing_user
    unit.save!
    @item.submitter          = users(:sally) # somebody else
    @item.primary_collection = collection

    policy = ItemPolicy.new(doing_user, @item)
    assert policy.destroy?
  end

  test "destroy?() does not authorize anyone else" do
    policy = ItemPolicy.new(users(:norights), @item)
    assert !policy.destroy?
  end

  # edit?()

  test "edit?() returns false with a nil user" do
    policy = ItemPolicy.new(nil, @item)
    assert !policy.edit?
  end

  test "edit?() does not authorize non-sysadmins" do
    policy = ItemPolicy.new(users(:norights), @item)
    assert !policy.edit?
  end

  test "edit?() authorizes sysadmins" do
    policy = ItemPolicy.new(users(:admin), @item)
    assert policy.edit?
  end

  test "edit?() authorizes the submission owner if the item is not in archive" do
    user = users(:norights)
    @item.submitter = user
    @item.in_archive = false
    policy = ItemPolicy.new(user, @item)
    assert policy.edit?
  end

  test "edit?() does not authorize the submission owner if the item is in archive" do
    user = users(:norights)
    @item.submitter = user
    @item.in_archive = true
    policy = ItemPolicy.new(user, @item)
    assert !policy.edit?
  end

  test "edit?() authorizes managers of the item's collection" do
    doing_user = users(:norights)
    collection = collections(:collection1)
    collection.managing_users << doing_user
    collection.save!
    @item.submitter          = users(:sally) # somebody else
    @item.primary_collection = collection

    policy = ItemPolicy.new(doing_user, @item)
    assert policy.edit?
  end

  test "edit?() authorizes admins of the item's collection's unit" do
    doing_user               = users(:norights)
    collection               = collections(:collection1)
    unit                     = collection.primary_unit
    unit.administering_users << doing_user
    unit.save!
    @item.submitter          = users(:sally) # somebody else
    @item.primary_collection = collection

    policy = ItemPolicy.new(doing_user, @item)
    assert policy.edit?
  end

  test "edit?() does not authorize anyone else" do
    policy = ItemPolicy.new(users(:norights), @item)
    assert !policy.edit?
  end

  # edit_metadata?()

  test "edit_metadata?() returns false with a nil user" do
    policy = ItemPolicy.new(nil, @item)
    assert !policy.edit_metadata?
  end

  test "edit_metadata?() is restrictive by default" do
    policy = ItemPolicy.new(users(:norights), @item)
    assert !policy.edit_metadata?
  end

  test "edit_metadata?() authorizes sysadmins" do
    policy = ItemPolicy.new(users(:admin), @item)
    assert policy.edit_metadata?
  end

  test "edit_metadata?() authorizes unit admins" do
    user = users(:norights)
    unit = @item.primary_collection.units.first
    unit.administrators.build(user: user)
    unit.save!
    policy = ItemPolicy.new(user, @item)
    assert policy.edit_metadata?
  end

  test "edit_metadata?() authorizes collection managers" do
    user = users(:norights)
    collection = @item.primary_collection
    collection.managers.build(user: user)
    collection.save!
    policy = ItemPolicy.new(user, @item)
    assert policy.edit_metadata?
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

  # show?()

  test "show_all_metadata?() returns false with a nil user" do
    policy = ItemPolicy.new(nil, @item)
    assert !policy.show_all_metadata?
  end

  test "show_all_metadata?() does not authorize non-sysadmins" do
    policy = ItemPolicy.new(users(:norights), @item)
    assert !policy.show_all_metadata?
  end

  test "show_all_metadata?() authorizes sysadmins" do
    policy = ItemPolicy.new(users(:admin), items(:undiscoverable))
    assert policy.show_all_metadata?
  end

  # update?()

  test "update?() returns false with a nil user" do
    policy = ItemPolicy.new(nil, @item)
    assert !policy.update?
  end

  test "update?() does not authorize non-sysadmins" do
    policy = ItemPolicy.new(users(:norights), @item)
    assert !policy.update?
  end

  test "update?() authorizes sysadmins" do
    policy = ItemPolicy.new(users(:admin), @item)
    assert policy.update?
  end

  test "update?() authorizes the submission owner if the item is not in archive" do
    user = users(:norights)
    @item.submitter = user
    @item.in_archive = false
    policy = ItemPolicy.new(user, @item)
    assert policy.update?
  end

  test "update?() does not authorize the submission owner if the item is in archive" do
    user = users(:norights)
    @item.submitter = user
    @item.in_archive = true
    policy = ItemPolicy.new(user, @item)
    assert !policy.update?
  end

  test "update?() authorizes managers of the submission's collection" do
    doing_user = users(:norights)
    collection = collections(:collection1)
    collection.managing_users << doing_user
    collection.save!
    @item.submitter          = users(:sally) # somebody else
    @item.primary_collection = collection

    policy = ItemPolicy.new(doing_user, @item)
    assert policy.update?
  end

  test "update?() authorizes admins of the submission's collection's unit" do
    doing_user               = users(:norights)
    collection               = collections(:collection1)
    unit                     = collection.primary_unit
    unit.administering_users << doing_user
    unit.save!
    @item.submitter          = users(:sally) # somebody else
    @item.primary_collection = collection

    policy = ItemPolicy.new(doing_user, @item)
    assert policy.update?
  end

  test "update?() does not authorize anyone else" do
    policy = ItemPolicy.new(users(:norights), @item)
    assert !policy.update?
  end

end
