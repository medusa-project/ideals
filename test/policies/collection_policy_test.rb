require 'test_helper'

class CollectionPolicyTest < ActiveSupport::TestCase

  setup do
    @collection = collections(:collection1)
  end

  # change_parent?()

  test "change_parent?() returns false with a nil user" do
    collection2 = collections(:described)
    policy      = CollectionPolicy.new(nil, @collection)
    assert !policy.change_parent?(collection2.id)
  end

  test "change_parent?() is restrictive by default" do
    context     = RequestContext.new(users(:norights), Role::NO_LIMIT)
    collection2 = collections(:described)
    policy      = CollectionPolicy.new(context, @collection)
    assert !policy.change_parent?(collection2.id)
  end

  test "change_parent?() authorizes sysadmins" do
    context     = RequestContext.new(users(:local_sysadmin), Role::NO_LIMIT)
    collection2 = collections(:described)
    policy      = CollectionPolicy.new(context, @collection)
    assert policy.change_parent?(collection2.id)
  end

  test "change_parent?() respects role limits" do
    # sysadmin user limited to an insufficient role
    context     = RequestContext.new(users(:local_sysadmin), Role::LOGGED_IN)
    collection2 = collections(:described)
    policy      = CollectionPolicy.new(context, @collection)
    assert !policy.change_parent?(collection2.id)
  end

  # children?()

  test "children?() returns true with a nil user" do
    policy = CollectionPolicy.new(nil, @collection)
    assert policy.children?
  end

  test "children?() authorizes everyone" do
    context = RequestContext.new(users(:norights), Role::NO_LIMIT)
    policy  = CollectionPolicy.new(context, @collection)
    assert policy.children?
  end

  # create?()

  test "create?() returns false with a nil user" do
    policy = CollectionPolicy.new(nil, @collection)
    assert !policy.create?
  end

  test "create?() is restrictive by default" do
    context = RequestContext.new(users(:norights), Role::NO_LIMIT)
    policy  = CollectionPolicy.new(context, @collection)
    assert !policy.create?
  end

  test "create?() authorizes sysadmins" do
    context = RequestContext.new(users(:local_sysadmin), Role::NO_LIMIT)
    policy  = CollectionPolicy.new(context, @collection)
    assert policy.create?
  end

  test "create?() authorizes unit admins" do
    user    = users(:norights)
    context = RequestContext.new(user, Role::NO_LIMIT)

    unit = @collection.units.first
    unit.administrators.build(user: user)
    unit.save!

    policy = CollectionPolicy.new(context, @collection)
    assert policy.create?
  end

  test "create?() authorizes collection managers" do
    user    = users(:norights)
    context = RequestContext.new(user, Role::NO_LIMIT)

    @collection.managing_users << user
    @collection.save!

    policy = CollectionPolicy.new(context, @collection)
    assert policy.create?
  end

  test "create?() works with class objects" do
    user    = users(:norights)
    context = RequestContext.new(user, Role::NO_LIMIT)
    policy  = CollectionPolicy.new(context, Collection)
    assert !policy.create?
  end

  test "create?() respects role limits" do
    # sysadmin user limited to an insufficient role
    context = RequestContext.new(users(:local_sysadmin), Role::COLLECTION_SUBMITTER)
    policy  = CollectionPolicy.new(context, @collection)
    assert !policy.create?
  end

  # destroy?()

  test "destroy?() returns false with a nil user" do
    policy = CollectionPolicy.new(nil, @collection)
    assert !policy.destroy?
  end

  test "destroy?() is restrictive by default" do
    context = RequestContext.new(users(:norights), Role::NO_LIMIT)
    policy  = CollectionPolicy.new(context, @collection)
    assert !policy.destroy?
  end

  test "destroy?() authorizes sysadmins" do
    context = RequestContext.new(users(:local_sysadmin), Role::NO_LIMIT)
    policy  = CollectionPolicy.new(context, @collection)
    assert policy.destroy?
  end

  test "destroy?() respects role limits" do
    # sysadmin user limited to an insufficient role
    context = RequestContext.new(users(:local_sysadmin), Role::COLLECTION_SUBMITTER)
    policy  = CollectionPolicy.new(context, @collection)
    assert !policy.destroy?
  end

  # edit_access?()

  test "edit_access?() returns false with a nil user" do
    policy = CollectionPolicy.new(nil, @collection)
    assert !policy.edit_access?
  end

  test "edit_access?() is restrictive by default" do
    context = RequestContext.new(users(:norights), Role::NO_LIMIT)
    policy  = CollectionPolicy.new(context, @collection)
    assert !policy.edit_access?
  end

  test "edit_access?() authorizes sysadmins" do
    context = RequestContext.new(users(:local_sysadmin), Role::NO_LIMIT)
    policy  = CollectionPolicy.new(context, @collection)
    assert policy.edit_access?
  end

  test "edit_access?() respects role limits" do
    # sysadmin user limited to an insufficient role
    context = RequestContext.new(users(:local_sysadmin), Role::COLLECTION_SUBMITTER)
    policy  = CollectionPolicy.new(context, @collection)
    assert !policy.edit_access?
  end

  # edit_collection_membership?()

  test "edit_collection_membership?() returns false with a nil user" do
    policy = CollectionPolicy.new(nil, @collection)
    assert !policy.edit_collection_membership?
  end

  test "edit_collection_membership?() is restrictive by default" do
    context = RequestContext.new(users(:norights), Role::NO_LIMIT)
    policy  = CollectionPolicy.new(context, @collection)
    assert !policy.edit_collection_membership?
  end

  test "edit_collection_membership?() authorizes sysadmins" do
    context = RequestContext.new(users(:local_sysadmin), Role::NO_LIMIT)
    policy  = CollectionPolicy.new(context, @collection)
    assert policy.edit_collection_membership?
  end

  test "edit_collection_membership?() respects role limits" do
    # sysadmin user limited to an insufficient role
    context = RequestContext.new(users(:local_sysadmin), Role::COLLECTION_SUBMITTER)
    policy  = CollectionPolicy.new(context, @collection)
    assert !policy.edit_collection_membership?
  end

  # edit_properties?()

  test "edit_properties?() returns false with a nil user" do
    policy = CollectionPolicy.new(nil, @collection)
    assert !policy.edit_properties?
  end

  test "edit_properties?() is restrictive by default" do
    context = RequestContext.new(users(:norights), Role::NO_LIMIT)
    policy  = CollectionPolicy.new(context, @collection)
    assert !policy.edit_properties?
  end

  test "edit_properties?() authorizes sysadmins" do
    context = RequestContext.new(users(:local_sysadmin), Role::NO_LIMIT)
    policy   = CollectionPolicy.new(context, @collection)
    assert policy.edit_properties?
  end

  test "edit_properties?() respects role limits" do
    # sysadmin user limited to an insufficient role
    context = RequestContext.new(users(:local_sysadmin), Role::COLLECTION_SUBMITTER)
    policy  = CollectionPolicy.new(context, @collection)
    assert !policy.edit_properties?
  end

  # edit_unit_membership?()

  test "edit_unit_membership?() returns false with a nil user" do
    policy = CollectionPolicy.new(nil, @collection)
    assert !policy.edit_unit_membership?
  end

  test "edit_unit_membership?() is restrictive by default" do
    context = RequestContext.new(users(:norights), Role::NO_LIMIT)
    policy  = CollectionPolicy.new(context, @collection)
    assert !policy.edit_unit_membership?
  end

  test "edit_unit_membership?() authorizes sysadmins" do
    context = RequestContext.new(users(:local_sysadmin), Role::NO_LIMIT)
    policy  = CollectionPolicy.new(context, @collection)
    assert policy.edit_unit_membership?
  end

  test "edit_unit_membership?() respects role limits" do
    # sysadmin user limited to an insufficient role
    context = RequestContext.new(users(:local_sysadmin), Role::COLLECTION_SUBMITTER)
    policy  = CollectionPolicy.new(context, @collection)
    assert !policy.edit_unit_membership?
  end

  # index?()

  test "index?() returns true with a nil user" do
    policy = CollectionPolicy.new(nil, Collection)
    assert policy.index?
  end

  test "index?() authorizes everyone" do
    context = RequestContext.new(users(:norights), Role::NO_LIMIT)
    policy  = CollectionPolicy.new(context, Collection)
    assert policy.index?
  end

  # new?()

  test "new?() returns false with a nil user" do
    policy = CollectionPolicy.new(nil, @collection)
    assert !policy.new?
  end

  test "new?() is restrictive by default" do
    context = RequestContext.new(users(:norights), Role::NO_LIMIT)
    policy  = CollectionPolicy.new(context, @collection)
    assert !policy.new?
  end

  test "new?() authorizes sysadmins" do
    context = RequestContext.new(users(:local_sysadmin), Role::NO_LIMIT)
    policy  = CollectionPolicy.new(context, @collection)
    assert policy.new?
  end

  test "new?() works with class objects" do
    user    = users(:norights)
    context = RequestContext.new(user, Role::NO_LIMIT)
    policy  = CollectionPolicy.new(context, Collection)
    assert !policy.new?
  end

  test "new?() respects role limits" do
    # sysadmin user limited to an insufficient role
    context = RequestContext.new(users(:local_sysadmin), Role::COLLECTION_SUBMITTER)
    policy  = CollectionPolicy.new(context, @collection)
    assert !policy.new?
  end

  # review_submissions?()

  test "review_submissions?() returns false with a nil user" do
    policy = CollectionPolicy.new(nil, @collection)
    assert !policy.review_submissions?
  end

  test "review_submissions?() is restrictive by default" do
    context = RequestContext.new(users(:norights), Role::NO_LIMIT)
    policy  = CollectionPolicy.new(context, @collection)
    assert !policy.review_submissions?
  end

  test "review_submissions?() authorizes sysadmins" do
    context = RequestContext.new(users(:local_sysadmin), Role::NO_LIMIT)
    policy  = CollectionPolicy.new(context, @collection)
    assert policy.review_submissions?
  end

  test "review_submissions?() authorizes collection managers" do
    user = users(:norights)
    user.managing_collections << @collection
    user.save!
    context = RequestContext.new(user, Role::NO_LIMIT)
    policy  = CollectionPolicy.new(context, @collection)
    assert policy.review_submissions?
  end

  test "review_submissions?() respects role limits" do
    # sysadmin user limited to an insufficient role
    context = RequestContext.new(users(:local_sysadmin), Role::LOGGED_IN)
    policy  = CollectionPolicy.new(context, @collection)
    assert !policy.review_submissions?
  end

  # show?()

  test "show?() returns true with a nil user" do
    policy = CollectionPolicy.new(nil, @collection)
    assert policy.show?
  end

  test "show?() authorizes everyone" do
    context = RequestContext.new(users(:norights), Role::NO_LIMIT)
    policy  = CollectionPolicy.new(context, @collection)
    assert policy.show?
  end

  # show_properties?()

  test "show_properties?() returns false with a nil user" do
    policy = CollectionPolicy.new(nil, @collection)
    assert !policy.show_properties?
  end

  test "show_properties?() is restrictive by default" do
    context = RequestContext.new(users(:norights), Role::NO_LIMIT)
    policy  = CollectionPolicy.new(context, @collection)
    assert !policy.show_properties?
  end

  test "show_properties?() authorizes sysadmins" do
    context = RequestContext.new(users(:local_sysadmin), Role::NO_LIMIT)
    policy  = CollectionPolicy.new(context, @collection)
    assert policy.show_properties?
  end

  test "show_properties?() authorizes collection managers" do
    user = users(:norights)
    user.managing_collections << @collection
    user.save!
    context = RequestContext.new(user, Role::NO_LIMIT)
    policy  = CollectionPolicy.new(context, @collection)
    assert policy.show_properties?
  end

  test "show_properties?() respects role limits" do
    # sysadmin user limited to an insufficient role
    context = RequestContext.new(users(:local_sysadmin), Role::LOGGED_IN)
    policy  = CollectionPolicy.new(context, @collection)
    assert !policy.show_properties?
  end

  # submit_item?()

  test "submit_item?() returns false with a nil user" do
    policy = CollectionPolicy.new(nil, @collection)
    assert !policy.submit_item?
  end

  test "submit_item?() is restrictive by default" do
    context = RequestContext.new(users(:norights), Role::NO_LIMIT)
    policy  = CollectionPolicy.new(context, @collection)
    assert !policy.submit_item?
  end

  test "submit_item?() authorizes sysadmins" do
    context = RequestContext.new(users(:local_sysadmin), Role::NO_LIMIT)
    policy  = CollectionPolicy.new(context, @collection)
    assert policy.submit_item?
  end

  test "submit_item?() authorizes unit admins" do
    user    = users(:norights)
    context = RequestContext.new(user, Role::NO_LIMIT)

    unit = @collection.units.first
    unit.administrators.build(user: user)
    unit.save!

    policy = CollectionPolicy.new(context, @collection)
    assert policy.submit_item?
  end

  test "submit_item?() authorizes collection managers" do
    user    = users(:norights)
    context = RequestContext.new(user, Role::NO_LIMIT)

    @collection.managing_users << user
    @collection.save!

    policy = CollectionPolicy.new(context, @collection)
    assert policy.submit_item?
  end

  test "submit_item?() authorizes collection submitters" do
    user    = users(:norights)
    context = RequestContext.new(user, Role::NO_LIMIT)

    @collection.submitting_users << user
    @collection.save!

    policy = CollectionPolicy.new(context, @collection)
    assert policy.submit_item?
  end

  test "submit_item?() respects role limits" do
    # sysadmin user limited to an insufficient role
    context = RequestContext.new(users(:local_sysadmin), Role::LOGGED_IN)
    policy  = CollectionPolicy.new(context, @collection)
    assert !policy.submit_item?
  end

  # update?()

  test "update?() returns false with a nil user" do
    policy = CollectionPolicy.new(nil, @collection)
    assert !policy.update?
  end

  test "update?() is restrictive by default" do
    context = RequestContext.new(users(:norights), Role::NO_LIMIT)
    policy  = CollectionPolicy.new(context, @collection)
    assert !policy.update?
  end

  test "update?() authorizes sysadmins" do
    context = RequestContext.new(users(:local_sysadmin), Role::NO_LIMIT)
    policy  = CollectionPolicy.new(context, @collection)
    assert policy.update?
  end

  test "update?() authorizes unit admins" do
    user    = users(:norights)
    context = RequestContext.new(user, Role::NO_LIMIT)

    unit = @collection.units.first
    unit.administrators.build(user: user)
    unit.save!

    policy = CollectionPolicy.new(context, @collection)
    assert policy.update?
  end

  test "update?() authorizes collection managers" do
    user    = users(:norights)
    context = RequestContext.new(user, Role::NO_LIMIT)

    @collection.managing_users << user
    @collection.save!

    policy = CollectionPolicy.new(context, @collection)
    assert policy.update?
  end

  test "update?() respects role limits" do
    # sysadmin user limited to an insufficient role
    context = RequestContext.new(users(:local_sysadmin), Role::COLLECTION_SUBMITTER)
    policy  = CollectionPolicy.new(context, @collection)
    assert !policy.update?
  end

end
