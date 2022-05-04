require 'test_helper'

class ItemPolicyTest < ActiveSupport::TestCase

  class ScopeTest < ActiveSupport::TestCase

    test "resolve() sets no filters for sysadmins" do
      user    = users(:local_sysadmin)
      context = RequestContext.new(user:        user,
                                   institution: user.institution)
      relation = ItemRelation.new
      scope    = ItemPolicy::Scope.new(context, relation)
      assert_equal 0, scope.resolve.instance_variable_get("@filters").length
    end

    test "resolve() sets filters for non-sysadmins" do
      user    = users(:norights)
      context = RequestContext.new(user:        user,
                                   institution: user.institution)
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

  # approve()

  test "approve?() returns false with a nil user" do
    policy = ItemPolicy.new(nil, @item)
    assert !policy.approve?
  end

  test "approve?() does not authorize non-sysadmins" do
    user    = users(:norights)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = ItemPolicy.new(context, @item)
    assert !policy.approve?
  end

  test "approve?() authorizes sysadmins" do
    user    = users(:local_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy = ItemPolicy.new(context, @item)
    assert policy.approve?
  end

  test "approve?() respects role limits" do
    # sysadmin user limited to an insufficient role
    user    = users(:local_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::COLLECTION_SUBMITTER)
    policy  = ItemPolicy.new(context, @item)
    assert !policy.approve?
  end

  # create?()

  test "create?() returns false with a nil user" do
    policy = ItemPolicy.new(nil, @item)
    assert !policy.create?
  end

  test "create?() is restrictive by default" do
    user    = users(:norights)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = ItemPolicy.new(context, @item)
    assert !policy.create?
  end

  test "create?() authorizes sysadmins" do
    user    = users(:local_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = ItemPolicy.new(context, @item)
    assert policy.create?
  end

  test "create?() authorizes unit admins" do
    user    = users(:norights)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)

    unit = @item.primary_collection.units.first
    unit.administrators.build(user: user)
    unit.save!

    policy = ItemPolicy.new(context, @item)
    assert policy.create?
  end

  test "create?() authorizes collection managers" do
    user    = users(:norights)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)

    collection = @item.primary_collection
    collection.managing_users << user
    collection.save!

    policy = ItemPolicy.new(context, @item)
    assert policy.create?
  end

  test "create?() authorizes collection submitters" do
    user    = users(:norights)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)

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

  # delete?()

  test "delete?() returns false with a nil user" do
    policy = ItemPolicy.new(nil, @item)
    assert !policy.delete?
  end

  test "delete?() authorizes sysadmins" do
    user    = users(:local_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = ItemPolicy.new(context, @item)
    assert policy.delete?
  end

  test "delete?() authorizes institution admins" do
    user    = users(:uiuc_admin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = ItemPolicy.new(context, @item)
    assert policy.delete?
  end

  test "delete?() authorizes the submission owner if the item is submitting" do
    user    = users(:norights)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)

    @item.submitter = user
    @item.stage     = Item::Stages::SUBMITTING

    policy = ItemPolicy.new(context, @item)
    assert policy.delete?
  end

  test "delete?() does not authorize the submission owner if the item is not
  submitting" do
    user    = users(:norights)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)

    @item.submitter = user
    @item.stage     = Item::Stages::APPROVED

    policy = ItemPolicy.new(context, @item)
    assert !policy.delete?
  end

  test "delete?() does not authorize anyone else" do
    user    = users(:norights)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = ItemPolicy.new(context, @item)
    assert !policy.delete?
  end

  test "delete?() respects role limits" do
    # sysadmin user limited to an insufficient role
    user    = users(:local_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::COLLECTION_SUBMITTER)
    policy  = ItemPolicy.new(context, @item)
    assert !policy.delete?
  end

  # download_counts?()

  test "download_counts?() returns true with a nil user" do
    policy = ItemPolicy.new(nil, @item)
    assert policy.download_counts?
  end

  test "download_counts?() restricts undiscoverable items by default" do
    user    = users(:norights)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = ItemPolicy.new(context, items(:undiscoverable))
    assert !policy.download_counts?
  end

  test "download_counts?() restricts submitting items by default" do
    user    = users(:norights)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = ItemPolicy.new(context, items(:submitting))
    assert !policy.download_counts?
  end

  test "download_counts?() restricts access to embargoed items" do
    user    = users(:norights)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    item    = items(:item1)
    policy  = ItemPolicy.new(context, item)
    assert policy.download_counts?
    item.embargoes.build(expires_at: Time.now + 1.hour,
                         full_access: true).save!
    assert !policy.download_counts?
  end

  test "download_counts?() does not restrict access to embargoed items when the
  current user is exempt from the embargo" do
    user         = users(:norights)
    group        = user_groups(:temp)
    group.users << user
    context      = RequestContext.new(user:        user,
                                      institution: user.institution)
    item         = items(:item1)
    policy       = ItemPolicy.new(context, item)
    assert policy.download_counts?

    item.embargoes.build(expires_at:  Time.now + 1.hour,
                         full_access: true,
                         user_groups: [group]).save!
    assert policy.download_counts?
  end

  test "download_counts?() restricts access to buried items" do
    user    = users(:norights)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    item    = items(:buried)
    policy  = ItemPolicy.new(context, item)
    assert !policy.download_counts?
  end

  test "download_counts?() authorizes sysadmins to undiscoverable items" do
    user    = users(:local_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = ItemPolicy.new(context, items(:undiscoverable))
    assert policy.download_counts?
  end

  test "download_counts?() authorizes sysadmins to submitting items" do
    user    = users(:local_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = ItemPolicy.new(context, items(:submitting))
    assert policy.download_counts?
  end

  test "download_counts?() authorizes sysadmins to withdrawn items" do
    user    = users(:local_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = ItemPolicy.new(context, items(:withdrawn))
    assert policy.download_counts?
  end

  test "download_counts?() respects role limits" do
    # sysadmin user limited to an insufficient role
    user    = users(:local_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::COLLECTION_SUBMITTER)
    policy  = ItemPolicy.new(context, items(:embargoed))
    assert !policy.download_counts?
  end

  # edit_embargoes?()

  test "edit_embargoes?() returns false with a nil user" do
    policy = ItemPolicy.new(nil, @item)
    assert !policy.edit_embargoes?
  end

  test "edit_embargoes?() is restrictive by default" do
    user    = users(:norights)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = ItemPolicy.new(context, @item)
    assert !policy.edit_embargoes?
  end

  test "edit_embargoes?() authorizes sysadmins" do
    user    = users(:local_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = ItemPolicy.new(context, @item)
    assert policy.edit_embargoes?
  end

  test "edit_embargoes?() authorizes unit admins" do
    user    = users(:norights)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    unit    = @item.primary_collection.units.first
    unit.administrators.build(user: user)
    unit.save!
    policy = ItemPolicy.new(context, @item)
    assert policy.edit_embargoes?
  end

  test "edit_embargoes?() authorizes collection managers" do
    user    = users(:norights)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    collection = @item.primary_collection
    collection.managers.build(user: user)
    collection.save!
    policy = ItemPolicy.new(context, @item)
    assert policy.edit_embargoes?
  end

  test "edit_embargoes?() respects role limits" do
    # sysadmin user limited to an insufficient role
    user    = users(:local_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::LOGGED_IN)
    policy  = ItemPolicy.new(context, @item)
    assert !policy.edit_embargoes?
  end

  # edit_membership?()

  test "edit_membership?() returns false with a nil user" do
    policy = ItemPolicy.new(nil, @item)
    assert !policy.edit_membership?
  end

  test "edit_membership?() is restrictive by default" do
    user    = users(:norights)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = ItemPolicy.new(context, @item)
    assert !policy.edit_membership?
  end

  test "edit_membership?() authorizes sysadmins" do
    user    = users(:local_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = ItemPolicy.new(context, @item)
    assert policy.edit_membership?
  end

  test "edit_membership?() authorizes unit admins" do
    user    = users(:norights)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    unit    = @item.primary_collection.units.first
    unit.administrators.build(user: user)
    unit.save!
    policy = ItemPolicy.new(context, @item)
    assert policy.edit_membership?
  end

  test "edit_membership?() authorizes collection managers" do
    user    = users(:norights)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
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
                                 institution: user.institution)
    policy = ItemPolicy.new(context, @item)
    assert !policy.edit_metadata?
  end

  test "edit_metadata?() authorizes sysadmins" do
    user    = users(:local_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = ItemPolicy.new(context, @item)
    assert policy.edit_metadata?
  end

  test "edit_metadata?() authorizes unit admins" do
    user    = users(:norights)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    unit    = @item.primary_collection.units.first
    unit.administrators.build(user: user)
    unit.save!
    policy = ItemPolicy.new(context, @item)
    assert policy.edit_metadata?
  end

  test "edit_metadata?() authorizes collection managers" do
    user       = users(:norights)
    context    = RequestContext.new(user:        user,
                                    institution: user.institution)
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
                                 institution: user.institution)
    policy  = ItemPolicy.new(context, @item)
    assert !policy.edit_properties?
  end

  test "edit_properties?() authorizes sysadmins" do
    user    = users(:local_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = ItemPolicy.new(context, @item)
    assert policy.edit_properties?
  end

  test "edit_properties?() authorizes unit admins" do
    user    = users(:norights)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    unit    = @item.primary_collection.units.first
    unit.administrators.build(user: user)
    unit.save!
    policy = ItemPolicy.new(context, @item)
    assert policy.edit_properties?
  end

  test "edit_properties?() authorizes collection managers" do
    user    = users(:norights)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
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

  # edit_withdrawal?()

  test "edit_withdrawal?() returns false with a nil user" do
    policy = ItemPolicy.new(nil, @item)
    assert !policy.edit_withdrawal?
  end

  test "edit_withdrawal?() does not authorize non-sysadmins" do
    user    = users(:norights)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = ItemPolicy.new(context, @item)
    assert !policy.edit_withdrawal?
  end

  test "edit_withdrawal?() authorizes sysadmins" do
    user    = users(:local_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = ItemPolicy.new(context, @item)
    assert policy.edit_withdrawal?
  end

  test "edit_withdrawal?() respects role limits" do
    # sysadmin user limited to an insufficient role
    user    = users(:local_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::COLLECTION_SUBMITTER)
    policy  = ItemPolicy.new(context, @item)
    assert !policy.edit_withdrawal?
  end

  # export?()

  test "export?() returns false with a nil user" do
    policy = ItemPolicy.new(nil, @item)
    assert !policy.export?
  end

  test "export?() authorizes sysadmins" do
    user    = users(:local_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = ItemPolicy.new(context, @item)
    assert policy.export?
  end

  test "export?() authorizes institution admins" do
    user    = users(:uiuc_admin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = ItemPolicy.new(context, @item)
    assert policy.export?
  end

  test "export?() does not authorize anyone else" do
    user    = users(:norights)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = ItemPolicy.new(context, @item)
    assert !policy.export?
  end

  test "export?() respects role limits" do
    # sysadmin user limited to an insufficient role
    user    = users(:local_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::COLLECTION_SUBMITTER)
    policy  = ItemPolicy.new(context, @item)
    assert !policy.export?
  end

  # index?()

  test "index?() returns true with a nil user" do
    policy = ItemPolicy.new(nil, Item)
    assert policy.index?
  end

  test "index?() authorizes everyone" do
    user    = users(:norights)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
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
                                 institution: user.institution)
    policy  = ItemPolicy.new(context, @item)
    assert !policy.ingest?
  end

  test "ingest?() authorizes sysadmins" do
    user    = users(:local_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = ItemPolicy.new(context, @item)
    assert policy.ingest?
  end

  test "ingest?() authorizes unit admins" do
    user    = users(:norights)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    unit    = @item.primary_collection.units.first
    unit.administrators.build(user: user)
    unit.save!
    policy = ItemPolicy.new(context, @item)
    assert policy.ingest?
  end

  test "ingest?() authorizes collection managers" do
    user    = users(:norights)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
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
                                 institution: user.institution)
    policy  = ItemPolicy.new(context, @item)
    assert !policy.process_review?
  end

  test "process_review?() authorizes sysadmins" do
    user    = users(:local_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
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

  # reject?()

  test "reject?() returns false with a nil user" do
    policy = ItemPolicy.new(nil, @item)
    assert !policy.reject?
  end

  test "reject?() does not authorize non-sysadmins" do
    user    = users(:norights)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = ItemPolicy.new(context, @item)
    assert !policy.reject?
  end

  test "reject?() authorizes sysadmins" do
    user    = users(:local_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy = ItemPolicy.new(context, @item)
    assert policy.reject?
  end

  test "reject?() respects role limits" do
    # sysadmin user limited to an insufficient role
    user    = users(:local_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::COLLECTION_SUBMITTER)
    policy  = ItemPolicy.new(context, @item)
    assert !policy.reject?
  end

  # review?()

  test "review?() returns false with a nil user" do
    policy = ItemPolicy.new(nil, @item)
    assert !policy.review?
  end

  test "review?() does not authorize non-sysadmins" do
    user    = users(:norights)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = ItemPolicy.new(context, @item)
    assert !policy.review?
  end

  test "review?() authorizes sysadmins" do
    user    = users(:local_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
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
                                 institution: user.institution)
    policy  = ItemPolicy.new(context, items(:undiscoverable))
    assert !policy.show?
  end

  test "show?() restricts submitting items by default" do
    user    = users(:norights)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = ItemPolicy.new(context, items(:submitting))
    assert !policy.show?
  end

  test "show?() restricts access to embargoed items" do
    user    = users(:norights)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    item    = items(:item1)
    policy  = ItemPolicy.new(context, item)
    assert policy.show?
    item.embargoes.build(expires_at: Time.now + 1.hour,
                         full_access: true).save!
    assert !policy.show?
  end

  test "show?() does not restrict access to embargoed items when the current
  user is exempt from the embargo" do
    user         = users(:norights)
    group        = user_groups(:temp)
    group.users << user
    context      = RequestContext.new(user:        user,
                                      institution: user.institution)
    item         = items(:item1)
    policy       = ItemPolicy.new(context, item)
    assert policy.show?

    item.embargoes.build(expires_at:  Time.now + 1.hour,
                         full_access: true,
                         user_groups: [group]).save!
    assert policy.show?
  end

  test "show?() authorizes sysadmins to undiscoverable items" do
    user    = users(:local_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = ItemPolicy.new(context, items(:undiscoverable))
    assert policy.show?
  end

  test "show?() authorizes sysadmins to submitting items" do
    user    = users(:local_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = ItemPolicy.new(context, items(:submitting))
    assert policy.show?
  end

  test "show?() authorizes sysadmins to withdrawn items" do
    user    = users(:local_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = ItemPolicy.new(context, items(:withdrawn))
    assert policy.show?
  end

  test "show?() authorizes sysadmins to buried items" do
    user    = users(:local_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = ItemPolicy.new(context, items(:buried))
    assert policy.show?
  end

  test "show?() respects role limits" do
    # sysadmin user limited to an insufficient role
    user    = users(:local_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::COLLECTION_SUBMITTER)
    policy  = ItemPolicy.new(context, items(:embargoed))
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
                                 institution: user.institution)
    policy  = ItemPolicy.new(context, @item)
    assert !policy.show_access?
  end

  test "show_access?() authorizes sysadmins" do
    user    = users(:local_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = ItemPolicy.new(context, @item)
    assert policy.show_access?
  end

  test "show_access?() authorizes unit admins" do
    user    = users(:norights)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    unit    = @item.primary_collection.units.first
    unit.administrators.build(user: user)
    unit.save!
    policy = ItemPolicy.new(context, @item)
    assert policy.show_access?
  end

  test "show_access?() authorizes collection managers" do
    user    = users(:norights)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
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
                                 institution: user.institution)
    policy  = ItemPolicy.new(context, @item)
    assert !policy.show_all_metadata?
  end

  test "show_all_metadata?() authorizes sysadmins" do
    user    = users(:local_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = ItemPolicy.new(context, items(:undiscoverable))
    assert policy.show_all_metadata?
  end

  test "show_all_metadata?() authorizes unit admins" do
    user    = users(:norights)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    unit    = @item.primary_collection.units.first
    unit.administrators.build(user: user)
    unit.save!
    policy = ItemPolicy.new(context, @item)
    assert policy.show_all_metadata?
  end

  test "show_all_metadata?() authorizes collection managers" do
    user    = users(:norights)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
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

  # show_collections?()

  test "show_collections?() returns true with a nil user to an item that is
  neither withdrawn nor buried" do
    policy = ItemPolicy.new(nil, @item)
    assert policy.show_collections?
  end

  test "show_collections?() authorizes sysadmins" do
    user    = users(:local_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = ItemPolicy.new(context, @item)
    assert policy.show_collections?
  end

  test "show_collections?() authorizes unit admins" do
    user    = users(:norights)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    unit    = @item.primary_collection.units.first
    unit.administrators.build(user: user)
    unit.save!
    policy = ItemPolicy.new(context, @item)
    assert policy.show_collections?
  end

  test "show_collections?() authorizes collection managers" do
    user    = users(:norights)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    collection = @item.primary_collection
    collection.managers.build(user: user)
    collection.save!
    policy = ItemPolicy.new(context, @item)
    assert policy.show_collections?
  end

  test "show_collections?() does not authorize access to withdrawn items by
  roles beneath collection manager" do
    @item   = items(:withdrawn)
    user    = users(:norights)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy = ItemPolicy.new(context, @item)
    assert !policy.show_collections?
  end

  test "show_collections?() does not authorize access to buried items by
  roles beneath collection manager" do
    @item   = items(:buried)
    user    = users(:norights)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy = ItemPolicy.new(context, @item)
    assert !policy.show_collections?
  end

  test "show_collections?() respects role limits" do
    @item   = items(:withdrawn)
    # sysadmin user limited to an insufficient role
    user    = users(:local_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::COLLECTION_SUBMITTER)
    policy  = ItemPolicy.new(context, @item)
    assert !policy.show_collections?
  end

  # show_embargoes?()

  test "show_embargoes?() returns false with a nil user" do
    policy = ItemPolicy.new(nil, @item)
    assert !policy.show_embargoes?
  end

  test "show_embargoes?() is restrictive by default" do
    user    = users(:norights)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = ItemPolicy.new(context, @item)
    assert !policy.show_embargoes?
  end

  test "show_embargoes?() authorizes sysadmins" do
    user    = users(:local_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = ItemPolicy.new(context, @item)
    assert policy.show_embargoes?
  end

  test "show_embargoes?() authorizes unit admins" do
    user    = users(:norights)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    unit    = @item.primary_collection.units.first
    unit.administrators.build(user: user)
    unit.save!
    policy = ItemPolicy.new(context, @item)
    assert policy.show_embargoes?
  end

  test "show_embargoes?() authorizes collection managers" do
    user    = users(:norights)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    collection = @item.primary_collection
    collection.managers.build(user: user)
    collection.save!
    policy = ItemPolicy.new(context, @item)
    assert policy.show_embargoes?
  end

  test "show_embargoes?() respects role limits" do
    # sysadmin user limited to an insufficient role
    user    = users(:local_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::COLLECTION_SUBMITTER)
    policy  = ItemPolicy.new(context, @item)
    assert !policy.show_embargoes?
  end

  # show_events?()

  test "show_events?() returns false with a nil user" do
    policy = ItemPolicy.new(nil, @item)
    assert !policy.show_events?
  end

  test "show_events?() is restrictive by default" do
    user    = users(:norights)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = ItemPolicy.new(context, @item)
    assert !policy.show_events?
  end

  test "show_events?() authorizes sysadmins" do
    user    = users(:local_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = ItemPolicy.new(context, @item)
    assert policy.show_events?
  end

  test "show_events?() authorizes unit admins" do
    user    = users(:norights)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    unit    = @item.primary_collection.units.first
    unit.administrators.build(user: user)
    unit.save!
    policy = ItemPolicy.new(context, @item)
    assert policy.show_events?
  end

  test "show_events?() authorizes collection managers" do
    user       = users(:norights)
    context    = RequestContext.new(user:        user,
                                    institution: user.institution)
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

  # show_file_navigator?()

  test "show_file_navigator?() authorizes sysadmins" do
    user    = users(:local_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = ItemPolicy.new(context, @item)
    assert policy.show_file_navigator?
  end

  test "show_file_navigator?() authorizes users belonging to an exempted user
  group on an embargo" do
    user              = users(:norights)
    user_group        = user_groups(:unused)
    user_group.users << user
    user_group.save!
    @item.embargoes.build(download:    true,
                          perpetual:   true,
                          user_groups: [user_group])

    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = ItemPolicy.new(context, @item)
    assert policy.show_file_navigator?
  end

  test "show_file_navigator?() does not authorize download-embargoed items" do
    @item   = items(:embargoed)
    user    = users(:norights)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = ItemPolicy.new(context, @item)
    assert !policy.show_file_navigator?
  end

  # show_metadata?()

  test "show_metadata?() returns true with a nil user to an item that is
  neither withdrawn nor buried" do
    policy = ItemPolicy.new(nil, @item)
    assert policy.show_metadata?
  end

  test "show_metadata?() authorizes sysadmins" do
    user    = users(:local_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = ItemPolicy.new(context, @item)
    assert policy.show_metadata?
  end

  test "show_metadata?() authorizes unit admins" do
    user    = users(:norights)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    unit    = @item.primary_collection.units.first
    unit.administrators.build(user: user)
    unit.save!
    policy = ItemPolicy.new(context, @item)
    assert policy.show_metadata?
  end

  test "show_metadata?() authorizes collection managers" do
    user    = users(:norights)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    collection = @item.primary_collection
    collection.managers.build(user: user)
    collection.save!
    policy = ItemPolicy.new(context, @item)
    assert policy.show_metadata?
  end

  test "show_metadata?() does not authorize access to withdrawn items by
  roles beneath collection manager" do
    @item   = items(:withdrawn)
    user    = users(:norights)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy = ItemPolicy.new(context, @item)
    assert !policy.show_metadata?
  end

  test "show_metadata?() does not authorize access to buried items by
  roles beneath collection manager" do
    @item   = items(:buried)
    user    = users(:norights)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy = ItemPolicy.new(context, @item)
    assert !policy.show_metadata?
  end

  test "show_metadata?() respects role limits" do
    @item   = items(:withdrawn)
    # sysadmin user limited to an insufficient role
    user    = users(:local_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::COLLECTION_SUBMITTER)
    policy  = ItemPolicy.new(context, @item)
    assert !policy.show_metadata?
  end

  # show_properties?()

  test "show_properties?() returns false with a nil user" do
    policy = ItemPolicy.new(nil, @item)
    assert !policy.show_properties?
  end

  test "show_properties?() is restrictive by default" do
    user    = users(:norights)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = ItemPolicy.new(context, @item)
    assert !policy.show_properties?
  end

  test "show_properties?() authorizes sysadmins" do
    user    = users(:local_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = ItemPolicy.new(context, @item)
    assert policy.show_properties?
  end

  test "show_properties?() authorizes unit admins" do
    user    = users(:norights)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    unit    = @item.primary_collection.units.first
    unit.administrators.build(user: user)
    unit.save!
    policy = ItemPolicy.new(context, @item)
    assert policy.show_properties?
  end

  test "show_properties?() authorizes collection managers" do
    user    = users(:norights)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
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
                                 institution: user.institution)
    policy  = ItemPolicy.new(context, @item)
    assert !policy.show_sysadmin_content?
  end

  test "show_sysadmin_content?() authorizes sysadmins" do
    user    = users(:local_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
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

  test "statistics?() returns true with a nil user" do
    policy = ItemPolicy.new(nil, @item)
    assert policy.statistics?
  end

  test "statistics?() restricts undiscoverable items by default" do
    user    = users(:norights)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = ItemPolicy.new(context, items(:undiscoverable))
    assert !policy.statistics?
  end

  test "statistics?() restricts submitting items by default" do
    user    = users(:norights)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = ItemPolicy.new(context, items(:submitting))
    assert !policy.statistics?
  end

  test "statistics?() restricts access to embargoed items" do
    user    = users(:norights)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    item    = items(:item1)
    policy  = ItemPolicy.new(context, item)
    assert policy.statistics?
    item.embargoes.build(expires_at: Time.now + 1.hour,
                         full_access: true).save!
    assert !policy.statistics?
  end

  test "statistics?() restricts access to buried items" do
    user    = users(:norights)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    item    = items(:buried)
    policy  = ItemPolicy.new(context, item)
    assert !policy.statistics?
  end

  test "statistics?() authorizes sysadmins to undiscoverable items" do
    user    = users(:local_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = ItemPolicy.new(context, items(:undiscoverable))
    assert policy.statistics?
  end

  test "statistics?() authorizes sysadmins to submitting items" do
    user    = users(:local_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = ItemPolicy.new(context, items(:submitting))
    assert policy.statistics?
  end

  test "statistics?() authorizes sysadmins to withdrawn items" do
    user    = users(:local_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = ItemPolicy.new(context, items(:withdrawn))
    assert policy.statistics?
  end

  test "statistics?() respects role limits" do
    # sysadmin user limited to an insufficient role
    user    = users(:local_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::COLLECTION_SUBMITTER)
    policy  = ItemPolicy.new(context, items(:embargoed))
    assert !policy.statistics?
  end

  # undelete?()

  test "undelete?() returns false with a nil user" do
    policy = ItemPolicy.new(nil, @item)
    assert !policy.undelete?
  end

  test "undelete?() authorizes sysadmins" do
    user    = users(:local_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = ItemPolicy.new(context, @item)
    assert policy.undelete?
  end

  test "undelete?() authorizes institution admins" do
    user    = users(:uiuc_admin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = ItemPolicy.new(context, @item)
    assert policy.undelete?
  end

  test "undelete?() does not authorize anyone else" do
    user    = users(:norights)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = ItemPolicy.new(context, @item)
    assert !policy.undelete?
  end

  test "undelete?() respects role limits" do
    # sysadmin user limited to an insufficient role
    user    = users(:local_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::COLLECTION_SUBMITTER)
    policy  = ItemPolicy.new(context, @item)
    assert !policy.undelete?
  end

  # update?()

  test "update?() returns false with a nil user" do
    policy = ItemPolicy.new(nil, @item)
    assert !policy.update?
  end

  test "update?() does not authorize non-sysadmins" do
    user    = users(:norights)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = ItemPolicy.new(context, @item)
    assert !policy.update?
  end

  test "update?() authorizes sysadmins" do
    user    = users(:local_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = ItemPolicy.new(context, @item)
    assert policy.update?
  end

  test "update?() authorizes the submission owner if the item is submitting" do
    user    = users(:norights)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    @item.submitter = user
    @item.stage     = Item::Stages::SUBMITTING
    policy = ItemPolicy.new(context, @item)
    assert policy.update?
  end

  test "update?() does not authorize the submission owner if the item is not submitting" do
    user       = users(:norights)
    context    = RequestContext.new(user:        user,
                                    institution: user.institution)
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
                                    institution: doing_user.institution)
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
                                    institution: doing_user.institution)
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
                                 institution: user.institution)
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
                                 institution: user.institution)
    policy  = ItemPolicy.new(context, @item)
    assert !policy.upload_bitstreams?
  end

  test "upload_bitstreams?() authorizes sysadmins" do
    user    = users(:local_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = ItemPolicy.new(context, @item)
    assert policy.upload_bitstreams?
  end

  test "upload_bitstreams?() authorizes unit admins" do
    user    = users(:norights)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    unit    = @item.primary_collection.units.first
    unit.administrators.build(user: user)
    unit.save!
    policy = ItemPolicy.new(context, @item)
    assert policy.upload_bitstreams?
  end

  test "upload_bitstreams?() authorizes collection managers" do
    user       = users(:norights)
    context    = RequestContext.new(user:        user,
                                    institution: user.institution)
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

  # withdraw?()

  test "withdraw?() returns false with a nil user" do
    policy = ItemPolicy.new(nil, @item)
    assert !policy.withdraw?
  end

  test "withdraw?() does not authorize non-unit-admins" do
    user    = users(:norights)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = ItemPolicy.new(context, @item)
    assert !policy.withdraw?
  end

  test "withdraw?() authorizes unit admins" do
    user = users(:norights)
    unit = @item.effective_primary_unit
    unit.administering_users << user
    unit.save!
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy = ItemPolicy.new(context, @item)
    assert policy.withdraw?
  end

  test "withdraw?() respects role limits" do
    # sysadmin user limited to an insufficient role
    user    = users(:local_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::COLLECTION_SUBMITTER)
    policy  = ItemPolicy.new(context, @item)
    assert !policy.withdraw?
  end

end
