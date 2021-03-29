require 'test_helper'

class ItemPolicyTest < ActiveSupport::TestCase

  class ScopeTest < ActiveSupport::TestCase

    test "resolve() sets no filters for sysadmins" do
      user    = users(:local_sysadmin)
      context = RequestContext.new(user:        user,
                                   institution: user.institution,
                                   role_limit:  Role::NO_LIMIT)
      relation = ItemRelation.new
      scope    = ItemPolicy::Scope.new(context, relation)
      assert_equal 0, scope.resolve.instance_variable_get("@filters").length
    end

    test "resolve() sets filters for non-sysadmins" do
      user    = users(:norights)
      context = RequestContext.new(user:        user,
                                   institution: user.institution,
                                   role_limit:  Role::NO_LIMIT)
      relation = ItemRelation.new
      scope    = ItemPolicy::Scope.new(context, relation)
      assert_equal [
                       [Item::IndexFields::DISCOVERABLE, true],
                       [Item::IndexFields::STAGE, Item::Stages::APPROVED]
                   ],
                   scope.resolve.instance_variable_get("@filters")
    end

    test "resolve() respects role limits" do
      user    = users(:local_sysadmin)
      context = RequestContext.new(user:        user,
                                   institution: user.institution,
                                   role_limit:  Role::LOGGED_IN)
      relation = ItemRelation.new
      scope    = ItemPolicy::Scope.new(context, relation)
      assert_equal [
                       [Item::IndexFields::DISCOVERABLE, true],
                       [Item::IndexFields::STAGE, Item::Stages::APPROVED]
                   ],
                   scope.resolve.instance_variable_get("@filters")
    end

  end

  setup do
    @item = items(:item1)
  end

  # create?()

  test "create?() returns false with a nil user" do
    policy = ItemPolicy.new(nil, @item)
    assert !policy.create?
  end

  test "create?() is restrictive by default" do
    user    = users(:norights)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::NO_LIMIT)
    policy  = ItemPolicy.new(context, @item)
    assert !policy.create?
  end

  test "create?() authorizes sysadmins" do
    user    = users(:local_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::NO_LIMIT)
    policy  = ItemPolicy.new(context, @item)
    assert policy.create?
  end

  test "create?() authorizes unit admins" do
    user    = users(:norights)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::NO_LIMIT)

    unit = @item.primary_collection.units.first
    unit.administrators.build(user: user)
    unit.save!

    policy = ItemPolicy.new(context, @item)
    assert policy.create?
  end

  test "create?() authorizes collection managers" do
    user    = users(:norights)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::NO_LIMIT)

    collection = @item.primary_collection
    collection.managing_users << user
    collection.save!

    policy = ItemPolicy.new(context, @item)
    assert policy.create?
  end

  test "create?() authorizes collection submitters" do
    user    = users(:norights)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::NO_LIMIT)

    collection = @item.primary_collection
    collection.submitting_users << user
    collection.save!

    policy = ItemPolicy.new(context, @item)
    assert policy.create?
  end

  test "create?() respects role limits" do
    # sysadmin user limited to an insufficient role
    user    = users(:local_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::LOGGED_IN)
    policy  = ItemPolicy.new(context, @item)
    assert !policy.create?
  end

  # data?()

  test "data?() returns true with a nil user" do
    policy = ItemPolicy.new(nil, @item)
    assert policy.data?
  end

  test "data?() restricts undiscoverable items by default" do
    user    = users(:norights)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::NO_LIMIT)
    policy  = ItemPolicy.new(context, items(:undiscoverable))
    assert !policy.data?
  end

  test "data?() restricts submitting items by default" do
    user    = users(:norights)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::NO_LIMIT)
    policy  = ItemPolicy.new(context, items(:submitting))
    assert !policy.data?
  end

  test "data?() restricts withdrawn items by default" do
    user    = users(:norights)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::NO_LIMIT)
    policy  = ItemPolicy.new(context, items(:withdrawn))
    assert !policy.data?
  end

  test "data?() authorizes sysadmins to undiscoverable items" do
    user    = users(:local_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::NO_LIMIT)
    policy  = ItemPolicy.new(context, items(:undiscoverable))
    assert policy.data?
  end

  test "data?() authorizes sysadmins to submitting items" do
    user    = users(:local_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::NO_LIMIT)
    policy  = ItemPolicy.new(context, items(:submitting))
    assert policy.data?
  end

  test "data?() authorizes sysadmins to withdrawn items" do
    user    = users(:local_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::NO_LIMIT)
    policy  = ItemPolicy.new(context, items(:withdrawn))
    assert policy.data?
  end

  test "data?() respects role limits" do
    # sysadmin user limited to an insufficient role
    user    = users(:local_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::COLLECTION_SUBMITTER)
    policy  = ItemPolicy.new(context, items(:withdrawn))
    assert !policy.data?
  end

  # destroy?()

  test "destroy?() returns false with a nil user" do
    policy = ItemPolicy.new(nil, @item)
    assert !policy.destroy?
  end

  test "destroy?() does not authorize non-sysadmins" do
    user    = users(:norights)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::NO_LIMIT)
    policy  = ItemPolicy.new(context, @item)
    assert !policy.destroy?
  end

  test "destroy?() authorizes sysadmins" do
    user    = users(:local_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::NO_LIMIT)
    policy  = ItemPolicy.new(context, @item)
    assert policy.destroy?
  end

  test "destroy?() authorizes the submission owner if the item is submitting" do
    user    = users(:norights)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::NO_LIMIT)

    @item.submitter = user
    @item.stage     = Item::Stages::SUBMITTING

    policy = ItemPolicy.new(context, @item)
    assert policy.destroy?
  end

  test "destroy?() does not authorize the submission owner if the item is not submitting" do
    user    = users(:norights)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::NO_LIMIT)

    @item.submitter = user
    @item.stage     = Item::Stages::APPROVED

    policy = ItemPolicy.new(context, @item)
    assert !policy.destroy?
  end

  test "destroy?() authorizes managers of the submission's collection" do
    doing_user = users(:norights)
    context    = RequestContext.new(user:        doing_user,
                                    institution: doing_user.institution,
                                    role_limit:  Role::NO_LIMIT)
    collection = collections(:collection1)
    collection.managing_users << doing_user
    collection.save!

    @item.submitter          = users(:norights) # somebody else
    @item.primary_collection = collection

    policy = ItemPolicy.new(context, @item)
    assert policy.destroy?
  end

  test "destroy?() authorizes admins of the submission's collection's unit" do
    doing_user = users(:norights)
    context    = RequestContext.new(user:        doing_user,
                                    institution: doing_user.institution,
                                    role_limit:  Role::NO_LIMIT)
    collection               = collections(:collection1)
    unit                     = collection.primary_unit
    unit.administering_users << doing_user
    unit.save!

    @item.submitter          = users(:norights) # somebody else
    @item.primary_collection = collection

    policy = ItemPolicy.new(context, @item)
    assert policy.destroy?
  end

  test "destroy?() does not authorize anyone else" do
    user    = users(:norights)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::NO_LIMIT)
    policy  = ItemPolicy.new(context, @item)
    assert !policy.destroy?
  end

  test "destroy?() respects role limits" do
    # sysadmin user limited to an insufficient role
    user    = users(:local_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::COLLECTION_SUBMITTER)
    policy  = ItemPolicy.new(context, @item)
    assert !policy.destroy?
  end

  # download_counts?()

  test "download_counts?() returns false with a nil user" do
    policy = ItemPolicy.new(nil, @item)
    assert !policy.download_counts?
  end

  test "download_counts?() does not authorize non-sysadmins" do
    user    = users(:norights)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::NO_LIMIT)
    policy  = ItemPolicy.new(context, @item)
    assert !policy.download_counts?
  end

  test "download_counts?() authorizes sysadmins" do
    user    = users(:local_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::NO_LIMIT)
    policy  = ItemPolicy.new(context, @item)
    assert policy.download_counts?
  end

  test "download_counts?() authorizes the submission owner if the item is submitting" do
    user    = users(:norights)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::NO_LIMIT)
    @item.submitter = user
    @item.stage     = Item::Stages::SUBMITTING
    policy = ItemPolicy.new(context, @item)
    assert policy.download_counts?
  end

  test "download_counts?() does not authorize the submission owner if the item is not submitting" do
    user       = users(:norights)
    context    = RequestContext.new(user:        user,
                                    institution: user.institution,
                                    role_limit:  Role::NO_LIMIT)
    collection = @item.primary_collection
    collection.submitting_users << user
    collection.save!
    @item.submitter = user
    @item.stage     = Item::Stages::APPROVED
    policy = ItemPolicy.new(context, @item)
    assert !policy.download_counts?
  end

  test "download_counts?() authorizes managers of the submission's collection" do
    doing_user = users(:norights)
    context    = RequestContext.new(user:        doing_user,
                                    institution: doing_user.institution,
                                    role_limit:  Role::NO_LIMIT)
    collection = collections(:collection1)
    collection.managing_users << doing_user
    collection.save!
    @item.submitter          = users(:norights) # somebody else
    @item.primary_collection = collection

    policy = ItemPolicy.new(context, @item)
    assert policy.download_counts?
  end

  test "download_counts?() authorizes admins of the submission's collection's unit" do
    doing_user = users(:norights)
    context    = RequestContext.new(user:        doing_user,
                                    institution: doing_user.institution,
                                    role_limit:  Role::NO_LIMIT)
    collection               = collections(:collection1)
    unit                     = collection.primary_unit
    unit.administering_users << doing_user
    unit.save!
    @item.submitter          = users(:norights) # somebody else
    @item.primary_collection = collection

    policy = ItemPolicy.new(context, @item)
    assert policy.download_counts?
  end

  test "download_counts?() does not authorize anyone else" do
    user    = users(:norights)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::NO_LIMIT)
    policy  = ItemPolicy.new(context, @item)
    assert !policy.download_counts?
  end

  test "download_counts?() respects role limits" do
    # sysadmin user limited to an insufficient role
    user    = users(:local_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::COLLECTION_SUBMITTER)
    policy  = ItemPolicy.new(context, @item)
    assert !policy.download_counts?
  end

  # edit_membership?()

  test "edit_membership?() returns false with a nil user" do
    policy = ItemPolicy.new(nil, @item)
    assert !policy.edit_membership?
  end

  test "edit_membership?() is restrictive by default" do
    user    = users(:norights)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::NO_LIMIT)
    policy  = ItemPolicy.new(context, @item)
    assert !policy.edit_membership?
  end

  test "edit_membership?() authorizes sysadmins" do
    user    = users(:local_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::NO_LIMIT)
    policy  = ItemPolicy.new(context, @item)
    assert policy.edit_membership?
  end

  test "edit_membership?() authorizes unit admins" do
    user    = users(:norights)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::NO_LIMIT)
    unit    = @item.primary_collection.units.first
    unit.administrators.build(user: user)
    unit.save!
    policy = ItemPolicy.new(context, @item)
    assert policy.edit_membership?
  end

  test "edit_membership?() authorizes collection managers" do
    user    = users(:norights)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::NO_LIMIT)
    collection = @item.primary_collection
    collection.managers.build(user: user)
    collection.save!
    policy = ItemPolicy.new(context, @item)
    assert policy.edit_membership?
  end

  test "edit_membership?() respects role limits" do
    # sysadmin user limited to an insufficient role
    user    = users(:local_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::LOGGED_IN)
    policy  = ItemPolicy.new(context, @item)
    assert !policy.edit_membership?
  end

  # edit_metadata?()

  test "edit_metadata?() returns false with a nil user" do
    policy = ItemPolicy.new(nil, @item)
    assert !policy.edit_metadata?
  end

  test "edit_metadata?() is restrictive by default" do
    user    = users(:norights)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::NO_LIMIT)
    policy = ItemPolicy.new(context, @item)
    assert !policy.edit_metadata?
  end

  test "edit_metadata?() authorizes sysadmins" do
    user    = users(:local_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::NO_LIMIT)
    policy  = ItemPolicy.new(context, @item)
    assert policy.edit_metadata?
  end

  test "edit_metadata?() authorizes unit admins" do
    user    = users(:norights)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::NO_LIMIT)
    unit    = @item.primary_collection.units.first
    unit.administrators.build(user: user)
    unit.save!
    policy = ItemPolicy.new(context, @item)
    assert policy.edit_metadata?
  end

  test "edit_metadata?() authorizes collection managers" do
    user       = users(:norights)
    context    = RequestContext.new(user:        user,
                                    institution: user.institution,
                                    role_limit:  Role::NO_LIMIT)
    collection = @item.primary_collection
    collection.managers.build(user: user)
    collection.save!
    policy = ItemPolicy.new(context, @item)
    assert policy.edit_metadata?
  end

  test "edit_metadata?() respects role limits" do
    # sysadmin user limited to an insufficient role
    user    = users(:local_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::COLLECTION_SUBMITTER)
    policy  = ItemPolicy.new(context, @item)
    assert !policy.edit_metadata?
  end

  # edit_properties?()

  test "edit_properties?() returns false with a nil user" do
    policy = ItemPolicy.new(nil, @item)
    assert !policy.edit_properties?
  end

  test "edit_properties?() is restrictive by default" do
    user    = users(:norights)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::NO_LIMIT)
    policy  = ItemPolicy.new(context, @item)
    assert !policy.edit_properties?
  end

  test "edit_properties?() authorizes sysadmins" do
    user    = users(:local_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::NO_LIMIT)
    policy  = ItemPolicy.new(context, @item)
    assert policy.edit_properties?
  end

  test "edit_properties?() authorizes unit admins" do
    user    = users(:norights)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::NO_LIMIT)
    unit    = @item.primary_collection.units.first
    unit.administrators.build(user: user)
    unit.save!
    policy = ItemPolicy.new(context, @item)
    assert policy.edit_properties?
  end

  test "edit_properties?() authorizes collection managers" do
    user    = users(:norights)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::NO_LIMIT)
    collection = @item.primary_collection
    collection.managers.build(user: user)
    collection.save!
    policy = ItemPolicy.new(context, @item)
    assert policy.edit_properties?
  end

  test "edit_properties?() respects role limits" do
    # sysadmin user limited to an insufficient role
    user    = users(:local_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::COLLECTION_SUBMITTER)
    policy  = ItemPolicy.new(context, @item)
    assert !policy.edit_properties?
  end

  # index?()

  test "index?() returns true with a nil user" do
    policy = ItemPolicy.new(nil, Item)
    assert policy.index?
  end

  test "index?() authorizes everyone" do
    user    = users(:norights)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::NO_LIMIT)
    policy  = ItemPolicy.new(context, Item)
    assert policy.index?
  end

  # ingest?()

  test "ingest?() returns false with a nil user" do
    policy = ItemPolicy.new(nil, @item)
    assert !policy.ingest?
  end

  test "ingest?() is restrictive by default" do
    user    = users(:norights)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::NO_LIMIT)
    policy  = ItemPolicy.new(context, @item)
    assert !policy.ingest?
  end

  test "ingest?() authorizes sysadmins" do
    user    = users(:local_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::NO_LIMIT)
    policy  = ItemPolicy.new(context, @item)
    assert policy.ingest?
  end

  test "ingest?() authorizes unit admins" do
    user    = users(:norights)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::NO_LIMIT)
    unit    = @item.primary_collection.units.first
    unit.administrators.build(user: user)
    unit.save!
    policy = ItemPolicy.new(context, @item)
    assert policy.ingest?
  end

  test "ingest?() authorizes collection managers" do
    user    = users(:norights)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::NO_LIMIT)
    collection = @item.primary_collection
    collection.managers.build(user: user)
    collection.save!
    policy = ItemPolicy.new(context, @item)
    assert policy.ingest?
  end

  test "ingest?() respects role limits" do
    # sysadmin user limited to an insufficient role
    user    = users(:local_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::COLLECTION_SUBMITTER)
    policy  = ItemPolicy.new(context, @item)
    assert !policy.ingest?
  end

  # process_review?()

  test "process_review?() returns false with a nil user" do
    policy = ItemPolicy.new(nil, @item)
    assert !policy.process_review?
  end

  test "process_review?() does not authorize non-sysadmins" do
    user    = users(:norights)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::NO_LIMIT)
    policy  = ItemPolicy.new(context, @item)
    assert !policy.process_review?
  end

  test "process_review?() authorizes sysadmins" do
    user    = users(:local_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::NO_LIMIT)
    policy = ItemPolicy.new(context, @item)
    assert policy.process_review?
  end

  test "process_review?() respects role limits" do
    # sysadmin user limited to an insufficient role
    user    = users(:local_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::COLLECTION_SUBMITTER)
    policy  = ItemPolicy.new(context, @item)
    assert !policy.process_review?
  end

  # review?()

  test "review?() returns false with a nil user" do
    policy = ItemPolicy.new(nil, @item)
    assert !policy.review?
  end

  test "review?() does not authorize non-sysadmins" do
    user    = users(:norights)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::NO_LIMIT)
    policy  = ItemPolicy.new(context, @item)
    assert !policy.review?
  end

  test "review?() authorizes sysadmins" do
    user    = users(:local_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::NO_LIMIT)
    policy = ItemPolicy.new(context, @item)
    assert policy.review?
  end

  test "review?() respects role limits" do
    # sysadmin user limited to an insufficient role
    user    = users(:local_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::COLLECTION_SUBMITTER)
    policy  = ItemPolicy.new(context, @item)
    assert !policy.review?
  end

  # show?()

  test "show?() returns true with a nil user" do
    policy = ItemPolicy.new(nil, @item)
    assert policy.show?
  end

  test "show?() restricts undiscoverable items by default" do
    user    = users(:norights)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::NO_LIMIT)
    policy  = ItemPolicy.new(context, items(:undiscoverable))
    assert !policy.show?
  end

  test "show?() restricts submitting items by default" do
    user    = users(:norights)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::NO_LIMIT)
    policy  = ItemPolicy.new(context, items(:submitting))
    assert !policy.show?
  end

  test "show?() restricts withdrawn items by default" do
    user    = users(:norights)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::NO_LIMIT)
    policy  = ItemPolicy.new(context, items(:withdrawn))
    assert !policy.show?
  end

  test "show?() authorizes sysadmins to undiscoverable items" do
    user    = users(:local_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::NO_LIMIT)
    policy  = ItemPolicy.new(context, items(:undiscoverable))
    assert policy.show?
  end

  test "show?() authorizes sysadmins to submitting items" do
    user    = users(:local_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::NO_LIMIT)
    policy  = ItemPolicy.new(context, items(:submitting))
    assert policy.show?
  end

  test "show?() authorizes sysadmins to withdrawn items" do
    user    = users(:local_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::NO_LIMIT)
    policy  = ItemPolicy.new(context, items(:withdrawn))
    assert policy.show?
  end

  test "show?() respects role limits" do
    # sysadmin user limited to an insufficient role
    user    = users(:local_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::COLLECTION_SUBMITTER)
    policy  = ItemPolicy.new(context, items(:withdrawn))
    assert !policy.show?
  end

  # show_access?()

  test "show_access?() returns false with a nil user" do
    policy = ItemPolicy.new(nil, @item)
    assert !policy.show_access?
  end

  test "show_access?() is restrictive by default" do
    user    = users(:norights)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::NO_LIMIT)
    policy  = ItemPolicy.new(context, @item)
    assert !policy.show_access?
  end

  test "show_access?() authorizes sysadmins" do
    user    = users(:local_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::NO_LIMIT)
    policy  = ItemPolicy.new(context, @item)
    assert policy.show_access?
  end

  test "show_access?() authorizes unit admins" do
    user    = users(:norights)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::NO_LIMIT)
    unit    = @item.primary_collection.units.first
    unit.administrators.build(user: user)
    unit.save!
    policy = ItemPolicy.new(context, @item)
    assert policy.show_access?
  end

  test "show_access?() authorizes collection managers" do
    user    = users(:norights)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::NO_LIMIT)
    collection = @item.primary_collection
    collection.managers.build(user: user)
    collection.save!
    policy = ItemPolicy.new(context, @item)
    assert policy.show_access?
  end

  test "show_access?() respects role limits" do
    # sysadmin user limited to an insufficient role
    user    = users(:local_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::COLLECTION_SUBMITTER)
    policy  = ItemPolicy.new(context, @item)
    assert !policy.show_access?
  end

  # show_all_metadata?()

  test "show_all_metadata?() returns false with a nil user" do
    policy = ItemPolicy.new(nil, @item)
    assert !policy.show_all_metadata?
  end

  test "show_all_metadata?() is restrictive by default" do
    user    = users(:norights)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::NO_LIMIT)
    policy  = ItemPolicy.new(context, @item)
    assert !policy.show_all_metadata?
  end

  test "show_all_metadata?() authorizes sysadmins" do
    user    = users(:local_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::NO_LIMIT)
    policy  = ItemPolicy.new(context, items(:undiscoverable))
    assert policy.show_all_metadata?
  end

  test "show_all_metadata?() authorizes unit admins" do
    user    = users(:norights)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::NO_LIMIT)
    unit    = @item.primary_collection.units.first
    unit.administrators.build(user: user)
    unit.save!
    policy = ItemPolicy.new(context, @item)
    assert policy.show_all_metadata?
  end

  test "show_all_metadata?() authorizes collection managers" do
    user    = users(:norights)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::NO_LIMIT)
    collection = @item.primary_collection
    collection.managers.build(user: user)
    collection.save!
    policy = ItemPolicy.new(context, @item)
    assert policy.show_all_metadata?
  end

  test "show_all_metadata?() respects role limits" do
    # sysadmin user limited to an insufficient role
    user    = users(:local_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::COLLECTION_SUBMITTER)
    policy  = ItemPolicy.new(context, @item)
    assert !policy.show_all_metadata?
  end

  # show_events?()

  test "show_events?() returns false with a nil user" do
    policy = ItemPolicy.new(nil, @item)
    assert !policy.show_events?
  end

  test "show_events?() is restrictive by default" do
    user    = users(:norights)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::NO_LIMIT)
    policy  = ItemPolicy.new(context, @item)
    assert !policy.show_events?
  end

  test "show_events?() authorizes sysadmins" do
    user    = users(:local_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::NO_LIMIT)
    policy  = ItemPolicy.new(context, @item)
    assert policy.show_events?
  end

  test "show_events?() authorizes unit admins" do
    user    = users(:norights)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::NO_LIMIT)
    unit    = @item.primary_collection.units.first
    unit.administrators.build(user: user)
    unit.save!
    policy = ItemPolicy.new(context, @item)
    assert policy.show_events?
  end

  test "show_events?() authorizes collection managers" do
    user       = users(:norights)
    context    = RequestContext.new(user:        user,
                                    institution: user.institution,
                                    role_limit:  Role::NO_LIMIT)
    collection = @item.primary_collection
    collection.managers.build(user: user)
    collection.save!
    policy = ItemPolicy.new(context, @item)
    assert policy.show_events?
  end

  test "show_events?() respects role limits" do
    # sysadmin user limited to an insufficient role
    user    = users(:local_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::COLLECTION_SUBMITTER)
    policy  = ItemPolicy.new(context, @item)
    assert !policy.show_events?
  end

  # show_properties?()

  test "show_properties?() returns false with a nil user" do
    policy = ItemPolicy.new(nil, @item)
    assert !policy.show_properties?
  end

  test "show_properties?() is restrictive by default" do
    user    = users(:norights)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::NO_LIMIT)
    policy  = ItemPolicy.new(context, @item)
    assert !policy.show_properties?
  end

  test "show_properties?() authorizes sysadmins" do
    user    = users(:local_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::NO_LIMIT)
    policy  = ItemPolicy.new(context, @item)
    assert policy.show_properties?
  end

  test "show_properties?() authorizes unit admins" do
    user    = users(:norights)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::NO_LIMIT)
    unit    = @item.primary_collection.units.first
    unit.administrators.build(user: user)
    unit.save!
    policy = ItemPolicy.new(context, @item)
    assert policy.show_properties?
  end

  test "show_properties?() authorizes collection managers" do
    user    = users(:norights)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::NO_LIMIT)
    collection = @item.primary_collection
    collection.managers.build(user: user)
    collection.save!
    policy = ItemPolicy.new(context, @item)
    assert policy.show_properties?
  end

  test "show_properties?() respects role limits" do
    # sysadmin user limited to an insufficient role
    user    = users(:local_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::COLLECTION_SUBMITTER)
    policy  = ItemPolicy.new(context, @item)
    assert !policy.show_properties?
  end

  # show_sysadmin_content?()

  test "show_sysadmin_content?() returns false with a nil user" do
    policy = ItemPolicy.new(nil, @item)
    assert !policy.show_sysadmin_content?
  end

  test "show_sysadmin_content?() does not authorize non-sysadmins" do
    user    = users(:norights)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::NO_LIMIT)
    policy  = ItemPolicy.new(context, @item)
    assert !policy.show_sysadmin_content?
  end

  test "show_sysadmin_content?() authorizes sysadmins" do
    user    = users(:local_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::NO_LIMIT)
    policy = ItemPolicy.new(context, @item)
    assert policy.show_sysadmin_content?
  end

  test "show_sysadmin_content?() respects role limits" do
    # sysadmin user limited to an insufficient role
    user    = users(:local_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::COLLECTION_SUBMITTER)
    policy  = ItemPolicy.new(context, @item)
    assert !policy.show_sysadmin_content?
  end

  # statistics?()

  test "statistics?() returns false with a nil user" do
    policy = ItemPolicy.new(nil, @item)
    assert !policy.statistics?
  end

  test "statistics?() does not authorize non-sysadmins" do
    user    = users(:norights)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::NO_LIMIT)
    policy  = ItemPolicy.new(context, @item)
    assert !policy.statistics?
  end

  test "statistics?() authorizes sysadmins" do
    user    = users(:local_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::NO_LIMIT)
    policy  = ItemPolicy.new(context, @item)
    assert policy.statistics?
  end

  test "statistics?() authorizes the submission owner if the item is submitting" do
    user    = users(:norights)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::NO_LIMIT)
    @item.submitter = user
    @item.stage     = Item::Stages::SUBMITTING
    policy = ItemPolicy.new(context, @item)
    assert policy.statistics?
  end

  test "statistics?() does not authorize the submission owner if the item is not submitting" do
    user       = users(:norights)
    context    = RequestContext.new(user:        user,
                                    institution: user.institution,
                                    role_limit:  Role::NO_LIMIT)
    collection = @item.primary_collection
    collection.submitting_users << user
    collection.save!
    @item.submitter = user
    @item.stage     = Item::Stages::APPROVED
    policy = ItemPolicy.new(context, @item)
    assert !policy.statistics?
  end

  test "statistics?() authorizes managers of the submission's collection" do
    doing_user = users(:norights)
    context    = RequestContext.new(user:        doing_user,
                                    institution: doing_user.institution,
                                    role_limit:  Role::NO_LIMIT)
    collection = collections(:collection1)
    collection.managing_users << doing_user
    collection.save!
    @item.submitter          = users(:norights) # somebody else
    @item.primary_collection = collection

    policy = ItemPolicy.new(context, @item)
    assert policy.statistics?
  end

  test "statistics?() authorizes admins of the submission's collection's unit" do
    doing_user = users(:norights)
    context    = RequestContext.new(user:        doing_user,
                                    institution: doing_user.institution,
                                    role_limit:  Role::NO_LIMIT)
    collection               = collections(:collection1)
    unit                     = collection.primary_unit
    unit.administering_users << doing_user
    unit.save!
    @item.submitter          = users(:norights) # somebody else
    @item.primary_collection = collection

    policy = ItemPolicy.new(context, @item)
    assert policy.statistics?
  end

  test "statistics?() does not authorize anyone else" do
    user    = users(:norights)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::NO_LIMIT)
    policy  = ItemPolicy.new(context, @item)
    assert !policy.statistics?
  end

  test "statistics?() respects role limits" do
    # sysadmin user limited to an insufficient role
    user    = users(:local_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::COLLECTION_SUBMITTER)
    policy  = ItemPolicy.new(context, @item)
    assert !policy.statistics?
  end

  # update?()

  test "update?() returns false with a nil user" do
    policy = ItemPolicy.new(nil, @item)
    assert !policy.update?
  end

  test "update?() does not authorize non-sysadmins" do
    user    = users(:norights)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::NO_LIMIT)
    policy  = ItemPolicy.new(context, @item)
    assert !policy.update?
  end

  test "update?() authorizes sysadmins" do
    user    = users(:local_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::NO_LIMIT)
    policy  = ItemPolicy.new(context, @item)
    assert policy.update?
  end

  test "update?() authorizes the submission owner if the item is submitting" do
    user    = users(:norights)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::NO_LIMIT)
    @item.submitter = user
    @item.stage     = Item::Stages::SUBMITTING
    policy = ItemPolicy.new(context, @item)
    assert policy.update?
  end

  test "update?() does not authorize the submission owner if the item is not submitting" do
    user       = users(:norights)
    context    = RequestContext.new(user:        user,
                                    institution: user.institution,
                                    role_limit:  Role::NO_LIMIT)
    collection = @item.primary_collection
    collection.submitting_users << user
    collection.save!
    @item.submitter = user
    @item.stage     = Item::Stages::APPROVED
    policy = ItemPolicy.new(context, @item)
    assert !policy.update?
  end

  test "update?() authorizes managers of the submission's collection" do
    doing_user = users(:norights)
    context    = RequestContext.new(user:        doing_user,
                                    institution: doing_user.institution,
                                    role_limit:  Role::NO_LIMIT)
    collection = collections(:collection1)
    collection.managing_users << doing_user
    collection.save!
    @item.submitter          = users(:norights) # somebody else
    @item.primary_collection = collection

    policy = ItemPolicy.new(context, @item)
    assert policy.update?
  end

  test "update?() authorizes admins of the submission's collection's unit" do
    doing_user = users(:norights)
    context    = RequestContext.new(user:        doing_user,
                                    institution: doing_user.institution,
                                    role_limit:  Role::NO_LIMIT)
    collection               = collections(:collection1)
    unit                     = collection.primary_unit
    unit.administering_users << doing_user
    unit.save!
    @item.submitter          = users(:norights) # somebody else
    @item.primary_collection = collection

    policy = ItemPolicy.new(context, @item)
    assert policy.update?
  end

  test "update?() does not authorize anyone else" do
    user    = users(:norights)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::NO_LIMIT)
    policy  = ItemPolicy.new(context, @item)
    assert !policy.update?
  end

  test "update?() respects role limits" do
    # sysadmin user limited to an insufficient role
    user    = users(:local_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::COLLECTION_SUBMITTER)
    policy  = ItemPolicy.new(context, @item)
    assert !policy.update?
  end

  # upload_bitstreams?()

  test "upload_bitstreams?() returns false with a nil user" do
    policy = ItemPolicy.new(nil, @item)
    assert !policy.upload_bitstreams?
  end

  test "upload_bitstreams?() is restrictive by default" do
    user    = users(:norights)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::NO_LIMIT)
    policy  = ItemPolicy.new(context, @item)
    assert !policy.upload_bitstreams?
  end

  test "upload_bitstreams?() authorizes sysadmins" do
    user    = users(:local_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::NO_LIMIT)
    policy  = ItemPolicy.new(context, @item)
    assert policy.upload_bitstreams?
  end

  test "upload_bitstreams?() authorizes unit admins" do
    user    = users(:norights)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::NO_LIMIT)
    unit    = @item.primary_collection.units.first
    unit.administrators.build(user: user)
    unit.save!
    policy = ItemPolicy.new(context, @item)
    assert policy.upload_bitstreams?
  end

  test "upload_bitstreams?() authorizes collection managers" do
    user       = users(:norights)
    context    = RequestContext.new(user:        user,
                                    institution: user.institution,
                                    role_limit:  Role::NO_LIMIT)
    collection = @item.primary_collection
    collection.managers.build(user: user)
    collection.save!
    policy = ItemPolicy.new(context, @item)
    assert policy.upload_bitstreams?
  end

  test "upload_bitstreams?() respects role limits" do
    # sysadmin user limited to an insufficient role
    user    = users(:local_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::COLLECTION_SUBMITTER)
    policy  = ItemPolicy.new(context, @item)
    assert !policy.upload_bitstreams?
  end

end
