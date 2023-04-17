require 'test_helper'

class ItemPolicyTest < ActiveSupport::TestCase

  class ScopeTest < ActiveSupport::TestCase

    test "resolve() sets correct filters" do
      user    = users(:southwest)
      context = RequestContext.new(user:        user,
                                   institution: user.institution)
      relation = ItemRelation.new
      scope    = ItemPolicy::Scope.new(context, relation)
      assert_equal [
                       [Item::IndexFields::STAGE, Item::Stages::APPROVED]
                   ],
                   scope.resolve.instance_variable_get("@filters")
    end

    test "resolve() respects role limits" do
      user    = users(:southwest_sysadmin)
      context = RequestContext.new(user:        user,
                                   institution: user.institution,
                                   role_limit:  Role::LOGGED_IN)
      relation = ItemRelation.new
      scope    = ItemPolicy::Scope.new(context, relation)
      assert_equal [
                       [Item::IndexFields::STAGE, Item::Stages::APPROVED]
                   ],
                   scope.resolve.instance_variable_get("@filters")
    end

  end

  setup do
    @item = items(:southwest_unit1_collection1_item1)
  end

  # approve()

  test "approve?() does not authorize a nil user" do
    context = RequestContext.new(user:        nil,
                                 institution: @item.institution)
    policy = ItemPolicy.new(context, @item)
    assert !policy.approve?
  end

  test "approve?() does not authorize an incorrect scope" do
    context = RequestContext.new(user:        users(:southwest_admin),
                                 institution: institutions(:northeast))
    policy  = ItemPolicy.new(context, @item)
    assert !policy.approve?
  end

  test "approve?() does not authorize non-sysadmins" do
    user    = users(:southwest)
    context = RequestContext.new(user:        user,
                                 institution: @item.institution)
    policy  = ItemPolicy.new(context, @item)
    assert !policy.approve?
  end

  test "approve?() authorizes sysadmins" do
    user    = users(:southwest_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: @item.institution)
    policy = ItemPolicy.new(context, @item)
    assert policy.approve?
  end

  test "approve?() respects role limits" do
    # sysadmin user limited to an insufficient role
    user    = users(:southwest_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: @item.institution,
                                 role_limit:  Role::COLLECTION_SUBMITTER)
    policy  = ItemPolicy.new(context, @item)
    assert !policy.approve?
  end

  # create?()

  test "create?() does not authorize a nil user" do
    context = RequestContext.new(user:        nil,
                                 institution: @item.institution)
    policy = ItemPolicy.new(context, @item)
    assert !policy.create?
  end

  test "create?() does not authorize an incorrect scope" do
    context = RequestContext.new(user:        users(:southwest_admin),
                                 institution: institutions(:northeast))
    policy  = ItemPolicy.new(context, @item)
    assert !policy.create?
  end

  test "create?() is restrictive by default" do
    user    = users(:southwest)
    context = RequestContext.new(user:        user,
                                 institution: @item.institution)
    policy  = ItemPolicy.new(context, @item)
    assert !policy.create?
  end

  test "create?() authorizes sysadmins" do
    user    = users(:southwest_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: @item.institution)
    policy  = ItemPolicy.new(context, @item)
    assert policy.create?
  end

  test "create?() authorizes unit admins" do
    user    = users(:southwest)
    context = RequestContext.new(user:        user,
                                 institution: @item.institution)

    unit = @item.primary_collection.units.first
    unit.administrators.build(user: user)
    unit.save!

    policy = ItemPolicy.new(context, @item)
    assert policy.create?
  end

  test "create?() authorizes collection administrators" do
    user    = users(:southwest)
    context = RequestContext.new(user:        user,
                                 institution: @item.institution)

    collection = @item.primary_collection
    collection.administering_users << user
    collection.save!

    policy = ItemPolicy.new(context, @item)
    assert policy.create?
  end

  test "create?() authorizes collection submitters" do
    user    = users(:southwest)
    context = RequestContext.new(user:        user,
                                 institution: @item.institution)

    collection = @item.primary_collection
    collection.submitting_users << user
    collection.save!

    policy = ItemPolicy.new(context, @item)
    assert policy.create?
  end

  test "create?() respects role limits" do
    # sysadmin user limited to an insufficient role
    user    = users(:southwest_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: @item.institution,
                                 role_limit:  Role::LOGGED_IN)
    policy  = ItemPolicy.new(context, @item)
    assert !policy.create?
  end

  # delete?()

  test "delete?() does not authorize a nil user" do
    context = RequestContext.new(user:        nil,
                                 institution: @item.institution)
    policy  = ItemPolicy.new(context, @item)
    assert !policy.delete?
  end

  test "delete?() does not authorize an incorrect scope" do
    context = RequestContext.new(user:        users(:southwest_admin),
                                 institution: institutions(:northeast))
    policy  = ItemPolicy.new(context, @item)
    assert !policy.delete?
  end

  test "delete?() authorizes sysadmins" do
    user    = users(:southwest_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: @item.institution)
    policy  = ItemPolicy.new(context, @item)
    assert policy.delete?
  end

  test "delete?() authorizes institution admins" do
    user    = users(:southwest_admin)
    context = RequestContext.new(user:        user,
                                 institution: @item.institution)
    policy  = ItemPolicy.new(context, @item)
    assert policy.delete?
  end

  test "delete?() authorizes the submission owner if the item is submitting" do
    user    = users(:southwest)
    context = RequestContext.new(user:        user,
                                 institution: @item.institution)

    @item.submitter = user
    @item.stage     = Item::Stages::SUBMITTING

    policy = ItemPolicy.new(context, @item)
    assert policy.delete?
  end

  test "delete?() does not authorize the submission owner if the item is not
  submitting" do
    user    = users(:southwest)
    context = RequestContext.new(user:        user,
                                 institution: @item.institution)

    @item.submitter = user
    @item.stage     = Item::Stages::APPROVED

    policy = ItemPolicy.new(context, @item)
    assert !policy.delete?
  end

  test "delete?() does not authorize anyone else" do
    user    = users(:southwest)
    context = RequestContext.new(user:        user,
                                 institution: @item.institution)
    policy  = ItemPolicy.new(context, @item)
    assert !policy.delete?
  end

  test "delete?() respects role limits" do
    # sysadmin user limited to an insufficient role
    user    = users(:southwest_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: @item.institution,
                                 role_limit:  Role::LOGGED_IN)
    policy  = ItemPolicy.new(context, @item)
    assert !policy.delete?
  end

  # delete_bitstreams?()

  test "delete_bitstreams?() does not authorize a nil user" do
    context = RequestContext.new(user:        nil,
                                 institution: @item.institution)
    policy  = ItemPolicy.new(context, @item)
    assert !policy.delete_bitstreams?
  end

  test "delete_bitstreams?() does not authorize an incorrect scope" do
    context = RequestContext.new(user:        users(:southwest_admin),
                                 institution: institutions(:northeast))
    policy  = ItemPolicy.new(context, @item)
    assert !policy.delete_bitstreams?
  end

  test "delete_bitstreams?() authorizes sysadmins" do
    user    = users(:southwest_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: @item.institution)
    policy  = ItemPolicy.new(context, @item)
    assert policy.delete_bitstreams?
  end

  test "delete_bitstreams?() authorizes admins of the same institution" do
    user    = users(:southwest_admin)
    context = RequestContext.new(user:        user,
                                 institution: @item.institution)
    policy  = ItemPolicy.new(context, @item)
    assert policy.delete_bitstreams?
  end

  test "delete_bitstreams?() does not authorize admins of a different
  institution" do
    user    = users(:northeast_admin)
    context = RequestContext.new(user:        user,
                                 institution: @item.institution)
    policy  = ItemPolicy.new(context, @item)
    assert !policy.delete_bitstreams?
  end

  test "delete_bitstreams?() does not authorize the bitstream owner if the item
  is not submitting" do
    user    = users(:southwest)
    context = RequestContext.new(user:        user,
                                 institution: @item.institution)

    @item.update!(submitter: user, stage: Item::Stages::APPROVED)

    policy = ItemPolicy.new(context, @item)
    assert !policy.delete_bitstreams?
  end

  test "delete_bitstreams?() authorizes administrators of the bitstream's
  collection to submitting items" do
    doing_user = users(:southwest)
    context    = RequestContext.new(user:        doing_user,
                                    institution: doing_user.institution)
    collection = collections(:uiuc_collection1)
    collection.administering_users << doing_user
    collection.save!

    @item.update!(submitter:          users(:southwest), # somebody else
                  stage:              Item::Stages::SUBMITTING,
                  primary_collection: collection)

    policy = ItemPolicy.new(context, @item)
    assert policy.delete_bitstreams?
  end

  test "delete_bitstreams?() does not authorize administrators of the
  bitstream's collection to non-submitting items" do
    doing_user = users(:southwest)
    context    = RequestContext.new(user:        doing_user,
                                    institution: doing_user.institution)
    collection = collections(:uiuc_collection1)
    collection.administering_users << doing_user
    collection.save!

    @item.update!(submitter:          users(:southwest), # somebody else
                  stage:              Item::Stages::APPROVED,
                  primary_collection: collection)

    policy = ItemPolicy.new(context, @item)
    assert !policy.delete_bitstreams?
  end

  test "delete_bitstreams?() authorizes admins of the submission's collection's
  unit to submitting items" do
    doing_user    = users(:southwest)
    context       = RequestContext.new(user:        doing_user,
                                       institution: doing_user.institution)
    collection               = collections(:uiuc_collection1)
    unit                     = collection.primary_unit
    unit.administering_users << doing_user
    unit.save!

    @item.update!(submitter:          users(:southwest), # somebody else
                  stage:              Item::Stages::SUBMITTING,
                  primary_collection: collection)

    policy = ItemPolicy.new(context, @item)
    assert policy.delete_bitstreams?
  end

  test "delete_bitstreams?() does not authorize admins of the submission's
  collection's unit to non-submitting items" do
    doing_user    = users(:southwest)
    context       = RequestContext.new(user:        doing_user,
                                       institution: doing_user.institution)
    collection               = collections(:uiuc_collection1)
    unit                     = collection.primary_unit
    unit.administering_users << doing_user
    unit.save!

    @item.update!(submitter:          users(:southwest), # somebody else
                  stage:              Item::Stages::APPROVED,
                  primary_collection: collection)

    policy = ItemPolicy.new(context, @item)
    assert !policy.delete_bitstreams?
  end

  test "delete_bitstreams?() does not authorize anyone else" do
    user    = users(:southwest)
    context = RequestContext.new(user:        user,
                                 institution: @item.institution)
    policy  = ItemPolicy.new(context, @item)
    assert !policy.delete_bitstreams?
  end

  test "delete_bitstreams?() respects role limits" do
    # sysadmin user limited to an insufficient role
    user    = users(:southwest_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: @item.institution,
                                 role_limit:  Role::COLLECTION_SUBMITTER)
    policy  = ItemPolicy.new(context, @item)
    assert !policy.delete_bitstreams?
  end

  # download_counts?()

  test "download_counts?() returns true with a nil user" do
    context = RequestContext.new(user:        nil,
                                 institution: @item.institution)
    policy = ItemPolicy.new(context, @item)
    assert policy.download_counts?
  end

  test "download_counts?() does not authorize an incorrect scope" do
    context = RequestContext.new(user:        users(:southwest_admin),
                                 institution: institutions(:northeast))
    policy  = ItemPolicy.new(context, @item)
    assert !policy.download_counts?
  end

  test "download_counts?() restricts submitting items by default" do
    user    = users(:southwest)
    context = RequestContext.new(user:        user,
                                 institution: @item.institution)
    policy  = ItemPolicy.new(context, items(:southwest_unit1_collection1_submitting))
    assert !policy.download_counts?
  end

  test "download_counts?() restricts access to embargoed items" do
    user    = users(:southwest)
    context = RequestContext.new(user:        user,
                                 institution: @item.institution)
    policy  = ItemPolicy.new(context, @item)
    assert policy.download_counts?
    @item.embargoes.build(expires_at: Time.now + 1.hour,
                          kind:       Embargo::Kind::ALL_ACCESS).save!
    assert !policy.download_counts?
  end

  test "download_counts?() does not restrict access to embargoed items when the
  current user is exempt from the embargo" do
    user         = users(:southwest)
    group        = user_groups(:southwest_unused)
    group.users << user
    context      = RequestContext.new(user:        user,
                                      institution: @item.institution)
    policy       = ItemPolicy.new(context, @item)
    assert policy.download_counts?

    @item.embargoes.build(expires_at:  Time.now + 1.hour,
                          kind:        Embargo::Kind::ALL_ACCESS,
                          user_groups: [group]).save!
    assert policy.download_counts?
  end

  test "download_counts?() restricts access to buried items" do
    user    = users(:southwest)
    context = RequestContext.new(user:        user,
                                 institution: @item.institution)
    item    = items(:southwest_unit1_collection1_buried)
    policy  = ItemPolicy.new(context, item)
    assert !policy.download_counts?
  end

  test "download_counts?() authorizes sysadmins to embargoed items" do
    user    = users(:southwest_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: @item.institution)
    policy  = ItemPolicy.new(context, items(:southwest_unit1_collection1_embargoed))
    assert policy.download_counts?
  end

  test "download_counts?() authorizes sysadmins to submitting items" do
    user    = users(:southwest_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: @item.institution)
    policy  = ItemPolicy.new(context, items(:southwest_unit1_collection1_submitting))
    assert policy.download_counts?
  end

  test "download_counts?() authorizes sysadmins to withdrawn items" do
    user    = users(:southwest_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: @item.institution)
    policy  = ItemPolicy.new(context, items(:southwest_unit1_collection1_withdrawn))
    assert policy.download_counts?
  end

  test "download_counts?() respects role limits" do
    # sysadmin user limited to an insufficient role
    user    = users(:southwest_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: @item.institution,
                                 role_limit:  Role::COLLECTION_SUBMITTER)
    policy  = ItemPolicy.new(context, items(:southwest_unit1_collection1_embargoed))
    assert !policy.download_counts?
  end

  # edit_embargoes?()

  test "edit_embargoes?() does not authorize a nil user" do
    context = RequestContext.new(user:        nil,
                                 institution: @item.institution)
    policy  = ItemPolicy.new(context, @item)
    assert !policy.edit_embargoes?
  end

  test "edit_embargoes?() does not authorize an incorrect scope" do
    context = RequestContext.new(user:        users(:southwest_admin),
                                 institution: institutions(:northeast))
    policy  = ItemPolicy.new(context, @item)
    assert !policy.edit_embargoes?
  end

  test "edit_embargoes?() is restrictive by default" do
    user    = users(:southwest)
    context = RequestContext.new(user:        user,
                                 institution: @item.institution)
    policy  = ItemPolicy.new(context, @item)
    assert !policy.edit_embargoes?
  end

  test "edit_embargoes?() authorizes sysadmins" do
    user    = users(:southwest_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: @item.institution)
    policy  = ItemPolicy.new(context, @item)
    assert policy.edit_embargoes?
  end

  test "edit_embargoes?() authorizes unit admins" do
    user    = users(:southwest)
    context = RequestContext.new(user:        user,
                                 institution: @item.institution)
    unit    = @item.primary_collection.units.first
    unit.administrators.build(user: user)
    unit.save!
    policy = ItemPolicy.new(context, @item)
    assert policy.edit_embargoes?
  end

  test "edit_embargoes?() authorizes collection administrators" do
    user    = users(:southwest)
    context = RequestContext.new(user:        user,
                                 institution: @item.institution)
    collection = @item.primary_collection
    collection.administrators.build(user: user)
    collection.save!
    policy = ItemPolicy.new(context, @item)
    assert policy.edit_embargoes?
  end

  test "edit_embargoes?() respects role limits" do
    # sysadmin user limited to an insufficient role
    user    = users(:southwest_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: @item.institution,
                                 role_limit:  Role::LOGGED_IN)
    policy  = ItemPolicy.new(context, @item)
    assert !policy.edit_embargoes?
  end

  # edit_membership?()

  test "edit_membership?() does not authorize a nil user" do
    context = RequestContext.new(user:        nil,
                                 institution: @item.institution)
    policy  = ItemPolicy.new(context, @item)
    assert !policy.edit_membership?
  end

  test "edit_membership?() does not authorize an incorrect scope" do
    context = RequestContext.new(user:        users(:southwest_admin),
                                 institution: institutions(:northeast))
    policy  = ItemPolicy.new(context, @item)
    assert !policy.edit_membership?
  end

  test "edit_membership?() is restrictive by default" do
    user    = users(:southwest)
    context = RequestContext.new(user:        user,
                                 institution: @item.institution)
    policy  = ItemPolicy.new(context, @item)
    assert !policy.edit_membership?
  end

  test "edit_membership?() authorizes sysadmins" do
    user    = users(:southwest_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: @item.institution)
    policy  = ItemPolicy.new(context, @item)
    assert policy.edit_membership?
  end

  test "edit_membership?() authorizes unit admins" do
    user    = users(:southwest)
    context = RequestContext.new(user:        user,
                                 institution: @item.institution)
    unit    = @item.primary_collection.units.first
    unit.administrators.build(user: user)
    unit.save!
    policy = ItemPolicy.new(context, @item)
    assert policy.edit_membership?
  end

  test "edit_membership?() authorizes collection administrators" do
    user    = users(:southwest)
    context = RequestContext.new(user:        user,
                                 institution: @item.institution)
    collection = @item.primary_collection
    collection.administrators.build(user: user)
    collection.save!
    policy = ItemPolicy.new(context, @item)
    assert policy.edit_membership?
  end

  test "edit_membership?() respects role limits" do
    # sysadmin user limited to an insufficient role
    user    = users(:southwest_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: @item.institution,
                                 role_limit:  Role::LOGGED_IN)
    policy  = ItemPolicy.new(context, @item)
    assert !policy.edit_membership?
  end

  # edit_metadata?()

  test "edit_metadata?() does not authorize a nil user" do
    context = RequestContext.new(user:        nil,
                                 institution: @item.institution)
    policy  = ItemPolicy.new(context, @item)
    assert !policy.edit_metadata?
  end

  test "edit_metadata?() does not authorize an incorrect scope" do
    context = RequestContext.new(user:        users(:southwest_admin),
                                 institution: institutions(:northeast))
    policy  = ItemPolicy.new(context, @item)
    assert !policy.edit_metadata?
  end

  test "edit_metadata?() is restrictive by default" do
    user    = users(:southwest)
    context = RequestContext.new(user:        user,
                                 institution: @item.institution)
    policy = ItemPolicy.new(context, @item)
    assert !policy.edit_metadata?
  end

  test "edit_metadata?() authorizes sysadmins" do
    user    = users(:southwest_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: @item.institution)
    policy  = ItemPolicy.new(context, @item)
    assert policy.edit_metadata?
  end

  test "edit_metadata?() authorizes unit admins" do
    user    = users(:southwest)
    context = RequestContext.new(user:        user,
                                 institution: @item.institution)
    unit    = @item.primary_collection.units.first
    unit.administrators.build(user: user)
    unit.save!
    policy = ItemPolicy.new(context, @item)
    assert policy.edit_metadata?
  end

  test "edit_metadata?() authorizes collection administrators" do
    user       = users(:southwest)
    context    = RequestContext.new(user:        user,
                                    institution: @item.institution)
    collection = @item.primary_collection
    collection.administrators.build(user: user)
    collection.save!
    policy = ItemPolicy.new(context, @item)
    assert policy.edit_metadata?
  end

  test "edit_metadata?() respects role limits" do
    # sysadmin user limited to an insufficient role
    user    = users(:southwest_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: @item.institution,
                                 role_limit:  Role::COLLECTION_SUBMITTER)
    policy  = ItemPolicy.new(context, @item)
    assert !policy.edit_metadata?
  end

  # edit_properties?()

  test "edit_properties?() does not authorize a nil user" do
    context = RequestContext.new(user:        nil,
                                 institution: @item.institution)
    policy  = ItemPolicy.new(context, @item)
    assert !policy.edit_properties?
  end

  test "edit_properties?() does not authorize an incorrect scope" do
    context = RequestContext.new(user:        users(:southwest_admin),
                                 institution: institutions(:northeast))
    policy  = ItemPolicy.new(context, @item)
    assert !policy.edit_properties?
  end

  test "edit_properties?() is restrictive by default" do
    user    = users(:southwest)
    context = RequestContext.new(user:        user,
                                 institution: @item.institution)
    policy  = ItemPolicy.new(context, @item)
    assert !policy.edit_properties?
  end

  test "edit_properties?() authorizes sysadmins" do
    user    = users(:southwest_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: @item.institution)
    policy  = ItemPolicy.new(context, @item)
    assert policy.edit_properties?
  end

  test "edit_properties?() authorizes unit admins" do
    user    = users(:southwest)
    context = RequestContext.new(user:        user,
                                 institution: @item.institution)
    unit    = @item.primary_collection.units.first
    unit.administrators.build(user: user)
    unit.save!
    policy = ItemPolicy.new(context, @item)
    assert policy.edit_properties?
  end

  test "edit_properties?() authorizes collection administrators" do
    user    = users(:southwest)
    context = RequestContext.new(user:        user,
                                 institution: @item.institution)
    collection = @item.primary_collection
    collection.administrators.build(user: user)
    collection.save!
    policy = ItemPolicy.new(context, @item)
    assert policy.edit_properties?
  end

  test "edit_properties?() respects role limits" do
    # sysadmin user limited to an insufficient role
    user    = users(:southwest_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: @item.institution,
                                 role_limit:  Role::COLLECTION_SUBMITTER)
    policy  = ItemPolicy.new(context, @item)
    assert !policy.edit_properties?
  end

  # edit_withdrawal?()

  test "edit_withdrawal?() does not authorize a nil user" do
    context = RequestContext.new(user:        nil,
                                 institution: @item.institution)
    policy  = ItemPolicy.new(context, @item)
    assert !policy.edit_withdrawal?
  end

  test "edit_withdrawal?() does not authorize an incorrect scope" do
    context = RequestContext.new(user:        users(:southwest_admin),
                                 institution: institutions(:northeast))
    policy  = ItemPolicy.new(context, @item)
    assert !policy.edit_withdrawal?
  end

  test "edit_withdrawal?() does not authorize non-sysadmins" do
    user    = users(:southwest)
    context = RequestContext.new(user:        user,
                                 institution: @item.institution)
    policy  = ItemPolicy.new(context, @item)
    assert !policy.edit_withdrawal?
  end

  test "edit_withdrawal?() authorizes sysadmins" do
    user    = users(:southwest_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: @item.institution)
    policy  = ItemPolicy.new(context, @item)
    assert policy.edit_withdrawal?
  end

  test "edit_withdrawal?() respects role limits" do
    # sysadmin user limited to an insufficient role
    user    = users(:southwest_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: @item.institution,
                                 role_limit:  Role::COLLECTION_SUBMITTER)
    policy  = ItemPolicy.new(context, @item)
    assert !policy.edit_withdrawal?
  end

  # export?()

  test "export?() does not authorize a nil user" do
    context = RequestContext.new(user:        nil,
                                 institution: @item.institution)
    policy  = ItemPolicy.new(context, @item)
    assert !policy.export?
  end

  test "export?() authorizes sysadmins" do
    user    = users(:southwest_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: @item.institution)
    policy  = ItemPolicy.new(context, @item)
    assert policy.export?
  end

  test "export?() authorizes institution admins" do
    user    = users(:southwest_admin)
    context = RequestContext.new(user:        user,
                                 institution: @item.institution)
    policy  = ItemPolicy.new(context, @item)
    assert policy.export?
  end

  test "export?() does not authorize anyone else" do
    user    = users(:southwest)
    context = RequestContext.new(user:        user,
                                 institution: @item.institution)
    policy  = ItemPolicy.new(context, @item)
    assert !policy.export?
  end

  test "export?() respects role limits" do
    # sysadmin user limited to an insufficient role
    user    = users(:southwest_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: @item.institution,
                                 role_limit:  Role::COLLECTION_SUBMITTER)
    policy  = ItemPolicy.new(context, @item)
    assert !policy.export?
  end

  # file_navigator?()

  test "file_navigator?() returns true with an unrestricted approved item and a
  nil user" do
    context = RequestContext.new(user:        nil,
                                 institution: @item.institution)
    policy = ItemPolicy.new(context, @item)
    assert policy.file_navigator?
  end

  test "file_navigator?() does not authorize an incorrect scope" do
    context = RequestContext.new(user:        users(:southwest_admin),
                                 institution: institutions(:northeast))
    policy  = ItemPolicy.new(context, @item)
    assert !policy.file_navigator?
  end

  test "file_navigator?() restricts submitting items by default" do
    user    = users(:southwest)
    context = RequestContext.new(user:        user,
                                 institution: @item.institution)
    policy  = ItemPolicy.new(context, items(:southwest_unit1_collection1_submitting))
    assert !policy.file_navigator?
  end

  test "file_navigator?() restricts access to embargoed items" do
    user    = users(:southwest)
    context = RequestContext.new(user:        user,
                                 institution: @item.institution)
    policy  = ItemPolicy.new(context, @item)
    assert policy.file_navigator?
    @item.embargoes.build(expires_at: Time.now + 1.hour,
                          kind:       Embargo::Kind::ALL_ACCESS).save!
    assert !policy.file_navigator?
  end

  test "file_navigator?() does not restrict access to embargoed items when the
  current user is exempt from the embargo" do
    user         = users(:southwest)
    group        = user_groups(:southwest_unused)
    group.users << user
    context      = RequestContext.new(user:        user,
                                      institution: @item.institution)
    policy       = ItemPolicy.new(context, @item)
    assert policy.file_navigator?

    @item.embargoes.build(expires_at:  Time.now + 1.hour,
                          kind:        Embargo::Kind::ALL_ACCESS,
                          user_groups: [group]).save!
    assert policy.file_navigator?
  end

  test "file_navigator?() authorizes sysadmins to embargoed items" do
    user    = users(:southwest_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: @item.institution)
    policy  = ItemPolicy.new(context, items(:southwest_unit1_collection1_embargoed))
    assert policy.file_navigator?
  end

  test "file_navigator?() authorizes sysadmins to submitting items" do
    user    = users(:southwest_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: @item.institution)
    policy  = ItemPolicy.new(context, items(:southwest_unit1_collection1_submitting))
    assert policy.file_navigator?
  end

  test "file_navigator?() authorizes sysadmins to withdrawn items" do
    user    = users(:southwest_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: @item.institution)
    policy  = ItemPolicy.new(context, items(:southwest_unit1_collection1_withdrawn))
    assert policy.file_navigator?
  end

  test "file_navigator?() authorizes sysadmins to buried items" do
    user    = users(:southwest_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: @item.institution)
    policy  = ItemPolicy.new(context, items(:southwest_unit1_collection1_buried))
    assert policy.file_navigator?
  end

  test "file_navigator?() authorizes users belonging to an exempted user group
  on an embargo" do
    user              = users(:southwest)
    user_group        = user_groups(:southwest_unused)
    user_group.users << user
    user_group.save!
    @item.embargoes.build(kind:        Embargo::Kind::DOWNLOAD,
                          perpetual:   true,
                          user_groups: [user_group])

    context = RequestContext.new(user:        user,
                                 institution: @item.institution)
    policy  = ItemPolicy.new(context, @item)
    assert policy.file_navigator?
  end

  test "file_navigator?() does not authorize download-embargoed items to
  ordinary users" do
    @item   = items(:southwest_unit1_collection1_embargoed)
    user    = users(:southwest)
    context = RequestContext.new(user:        user,
                                 institution: @item.institution)
    policy  = ItemPolicy.new(context, @item)
    assert !policy.file_navigator?
  end

  test "file_navigator?() respects role limits" do
    # sysadmin user limited to an insufficient role
    user    = users(:southwest_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: @item.institution,
                                 role_limit:  Role::COLLECTION_SUBMITTER)
    policy  = ItemPolicy.new(context, items(:southwest_unit1_collection1_embargoed))
    assert !policy.file_navigator?
  end

  # index?()

  test "index?() returns true with a nil user" do
    context = RequestContext.new(user:        nil,
                                 institution: @item.institution)
    policy = ItemPolicy.new(context, Item)
    assert policy.index?
  end

  test "index?() authorizes everyone" do
    user    = users(:southwest)
    context = RequestContext.new(user:        user,
                                 institution: @item.institution)
    policy  = ItemPolicy.new(context, Item)
    assert policy.index?
  end

  # ingest?()

  test "ingest?() does not authorize a nil user" do
    context = RequestContext.new(user:        nil,
                                 institution: @item.institution)
    policy  = ItemPolicy.new(context, @item)
    assert !policy.ingest?
  end

  test "ingest?() does not authorize an incorrect scope" do
    context = RequestContext.new(user:        users(:southwest_admin),
                                 institution: institutions(:northeast))
    policy  = ItemPolicy.new(context, @item)
    assert !policy.ingest?
  end

  test "ingest?() is restrictive by default" do
    user    = users(:southwest)
    context = RequestContext.new(user:        user,
                                 institution: @item.institution)
    policy  = ItemPolicy.new(context, @item)
    assert !policy.ingest?
  end

  test "ingest?() authorizes sysadmins" do
    user    = users(:southwest_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: @item.institution)
    policy  = ItemPolicy.new(context, @item)
    assert policy.ingest?
  end

  test "ingest?() authorizes unit admins" do
    user    = users(:southwest)
    context = RequestContext.new(user:        user,
                                 institution: @item.institution)
    unit    = @item.primary_collection.units.first
    unit.administrators.build(user: user)
    unit.save!
    policy = ItemPolicy.new(context, @item)
    assert policy.ingest?
  end

  test "ingest?() authorizes collection administrators" do
    user    = users(:southwest)
    context = RequestContext.new(user:        user,
                                 institution: @item.institution)
    collection = @item.primary_collection
    collection.administrators.build(user: user)
    collection.save!
    policy = ItemPolicy.new(context, @item)
    assert policy.ingest?
  end

  test "ingest?() respects role limits" do
    # sysadmin user limited to an insufficient role
    user    = users(:southwest_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: @item.institution,
                                 role_limit:  Role::COLLECTION_SUBMITTER)
    policy  = ItemPolicy.new(context, @item)
    assert !policy.ingest?
  end

  # process_review?()

  test "process_review?() does not authorize a nil user" do
    context = RequestContext.new(user:        nil,
                                 institution: @item.institution)
    policy = ItemPolicy.new(context, @item)
    assert !policy.process_review?
  end

  test "process_review?() does not authorize an incorrect scope" do
    context = RequestContext.new(user:        users(:southwest_admin),
                                 institution: institutions(:northeast))
    policy  = ItemPolicy.new(context, @item)
    assert !policy.process_review?
  end

  test "process_review?() does not authorize non-sysadmins" do
    user    = users(:southwest)
    context = RequestContext.new(user:        user,
                                 institution: @item.institution)
    policy  = ItemPolicy.new(context, @item)
    assert !policy.process_review?
  end

  test "process_review?() authorizes sysadmins" do
    user    = users(:southwest_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: @item.institution)
    policy = ItemPolicy.new(context, @item)
    assert policy.process_review?
  end

  test "process_review?() respects role limits" do
    # sysadmin user limited to an insufficient role
    user    = users(:southwest_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: @item.institution,
                                 role_limit:  Role::COLLECTION_SUBMITTER)
    policy  = ItemPolicy.new(context, @item)
    assert !policy.process_review?
  end

  # reject?()

  test "reject?() does not authorize a nil user" do
    context = RequestContext.new(user:        nil,
                                 institution: @item.institution)
    policy = ItemPolicy.new(context, @item)
    assert !policy.reject?
  end

  test "reject?() does not authorize an incorrect scope" do
    context = RequestContext.new(user:        users(:southwest_admin),
                                 institution: institutions(:northeast))
    policy  = ItemPolicy.new(context, @item)
    assert !policy.reject?
  end

  test "reject?() does not authorize non-sysadmins" do
    user    = users(:southwest)
    context = RequestContext.new(user:        user,
                                 institution: @item.institution)
    policy  = ItemPolicy.new(context, @item)
    assert !policy.reject?
  end

  test "reject?() authorizes sysadmins" do
    user    = users(:southwest_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: @item.institution)
    policy = ItemPolicy.new(context, @item)
    assert policy.reject?
  end

  test "reject?() respects role limits" do
    # sysadmin user limited to an insufficient role
    user    = users(:southwest_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: @item.institution,
                                 role_limit:  Role::COLLECTION_SUBMITTER)
    policy  = ItemPolicy.new(context, @item)
    assert !policy.reject?
  end

  # review?()

  test "review?() does not authorize a nil user" do
    context = RequestContext.new(user:        nil,
                                 institution: @item.institution)
    policy = ItemPolicy.new(context, @item)
    assert !policy.review?
  end

  test "review?() does not authorize an incorrect scope" do
    context = RequestContext.new(user:        users(:southwest_admin),
                                 institution: institutions(:northeast))
    policy  = ItemPolicy.new(context, @item)
    assert !policy.review?
  end

  test "review?() does not authorize non-sysadmins" do
    user    = users(:southwest)
    context = RequestContext.new(user:        user,
                                 institution: @item.institution)
    policy  = ItemPolicy.new(context, @item)
    assert !policy.review?
  end

  test "review?() authorizes sysadmins" do
    user    = users(:southwest_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: @item.institution)
    policy = ItemPolicy.new(context, @item)
    assert policy.review?
  end

  test "review?() authorizes administrators of the same institution" do
    user = users(:southwest_admin)
    context = RequestContext.new(user:        user,
                                 institution: @item.institution)
    policy  = ItemPolicy.new(context, @item)
    assert policy.review?
  end

  test "review?() does not authorize administrators of a different
  institution" do
    user    = users(:southwest_admin)
    context = RequestContext.new(user:        user,
                                 institution: institutions(:northeast))
    policy  = ItemPolicy.new(context, @item)
    assert !policy.review?
  end

  test "review?() respects role limits" do
    # sysadmin user limited to an insufficient role
    user    = users(:southwest_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: @item.institution,
                                 role_limit:  Role::COLLECTION_SUBMITTER)
    policy  = ItemPolicy.new(context, @item)
    assert !policy.review?
  end

  # show?()

  test "show?() returns true with a nil user" do
    context = RequestContext.new(user:        nil,
                                 institution: @item.institution)
    policy = ItemPolicy.new(context, @item)
    assert policy.show?
  end

  test "show?() does not authorize an incorrect scope" do
    context = RequestContext.new(user:        users(:southwest_admin),
                                 institution: institutions(:northeast))
    policy  = ItemPolicy.new(context, @item)
    assert !policy.show?
  end

  test "show?() restricts submitting items by default" do
    user    = users(:southwest)
    context = RequestContext.new(user:        user,
                                 institution: @item.institution)
    policy  = ItemPolicy.new(context, items(:southwest_unit1_collection1_submitting))
    assert !policy.show?
  end

  test "show?() restricts access to embargoed items" do
    user    = users(:southwest)
    context = RequestContext.new(user:        user,
                                 institution: @item.institution)
    policy  = ItemPolicy.new(context, @item)
    assert policy.show?
    @item.embargoes.build(expires_at: Time.now + 1.hour,
                          kind:       Embargo::Kind::ALL_ACCESS).save!
    assert !policy.show?
  end

  test "show?() does not restrict access to embargoed items when the current
  user is exempt from the embargo" do
    user         = users(:southwest)
    group        = user_groups(:southwest_unused)
    group.users << user
    context      = RequestContext.new(user:        user,
                                      institution: @item.institution)
    policy       = ItemPolicy.new(context, @item)
    assert policy.show?

    @item.embargoes.build(expires_at:  Time.now + 1.hour,
                          kind:        Embargo::Kind::ALL_ACCESS,
                          user_groups: [group]).save!
    assert policy.show?
  end

  test "show?() authorizes sysadmins to embargoed items" do
    user    = users(:southwest_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: @item.institution)
    policy  = ItemPolicy.new(context, items(:southwest_unit1_collection1_embargoed))
    assert policy.show?
  end

  test "show?() authorizes sysadmins to submitting items" do
    user    = users(:southwest_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: @item.institution)
    policy  = ItemPolicy.new(context, items(:southwest_unit1_collection1_submitting))
    assert policy.show?
  end

  test "show?() authorizes sysadmins to withdrawn items" do
    user    = users(:southwest_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: @item.institution)
    policy  = ItemPolicy.new(context, items(:southwest_unit1_collection1_withdrawn))
    assert policy.show?
  end

  test "show?() authorizes sysadmins to buried items" do
    user    = users(:southwest_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: @item.institution)
    policy  = ItemPolicy.new(context, items(:southwest_unit1_collection1_buried))
    assert policy.show?
  end

  test "show?() respects role limits" do
    # sysadmin user limited to an insufficient role
    user    = users(:southwest_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: @item.institution,
                                 role_limit:  Role::COLLECTION_SUBMITTER)
    policy  = ItemPolicy.new(context, items(:southwest_unit1_collection1_embargoed))
    assert !policy.show?
  end

  # show_access?()

  test "show_access?() does not authorize a nil user" do
    context = RequestContext.new(user:        nil,
                                 institution: @item.institution)
    policy = ItemPolicy.new(context, @item)
    assert !policy.show_access?
  end

  test "show_access?() does not authorize an incorrect scope" do
    context = RequestContext.new(user:        users(:southwest_admin),
                                 institution: institutions(:northeast))
    policy  = ItemPolicy.new(context, @item)
    assert !policy.show_access?
  end

  test "show_access?() is restrictive by default" do
    user    = users(:southwest)
    context = RequestContext.new(user:        user,
                                 institution: @item.institution)
    policy  = ItemPolicy.new(context, @item)
    assert !policy.show_access?
  end

  test "show_access?() authorizes sysadmins" do
    user    = users(:southwest_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: @item.institution)
    policy  = ItemPolicy.new(context, @item)
    assert policy.show_access?
  end

  test "show_access?() authorizes unit admins" do
    user    = users(:southwest)
    context = RequestContext.new(user:        user,
                                 institution: @item.institution)
    unit    = @item.primary_collection.units.first
    unit.administrators.build(user: user)
    unit.save!
    policy = ItemPolicy.new(context, @item)
    assert policy.show_access?
  end

  test "show_access?() authorizes collection administrators" do
    user    = users(:southwest)
    context = RequestContext.new(user:        user,
                                 institution: @item.institution)
    collection = @item.primary_collection
    collection.administrators.build(user: user)
    collection.save!
    policy = ItemPolicy.new(context, @item)
    assert policy.show_access?
  end

  test "show_access?() respects role limits" do
    # sysadmin user limited to an insufficient role
    user    = users(:southwest_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: @item.institution,
                                 role_limit:  Role::COLLECTION_SUBMITTER)
    policy  = ItemPolicy.new(context, @item)
    assert !policy.show_access?
  end

  # show_all_metadata?()

  test "show_all_metadata?() does not authorize a nil user" do
    context = RequestContext.new(user:        nil,
                                 institution: @item.institution)
    policy = ItemPolicy.new(context, @item)
    assert !policy.show_all_metadata?
  end

  test "show_all_metadata?() does not authorize an incorrect scope" do
    context = RequestContext.new(user:        users(:southwest_admin),
                                 institution: institutions(:northeast))
    policy  = ItemPolicy.new(context, @item)
    assert !policy.show_all_metadata?
  end

  test "show_all_metadata?() is restrictive by default" do
    user    = users(:southwest)
    context = RequestContext.new(user:        user,
                                 institution: @item.institution)
    policy  = ItemPolicy.new(context, @item)
    assert !policy.show_all_metadata?
  end

  test "show_all_metadata?() authorizes sysadmins" do
    user    = users(:southwest_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: @item.institution)
    policy  = ItemPolicy.new(context, items(:southwest_unit1_collection1_embargoed))
    assert policy.show_all_metadata?
  end

  test "show_all_metadata?() authorizes unit admins" do
    user    = users(:southwest)
    context = RequestContext.new(user:        user,
                                 institution: @item.institution)
    unit    = @item.primary_collection.units.first
    unit.administrators.build(user: user)
    unit.save!
    policy = ItemPolicy.new(context, @item)
    assert policy.show_all_metadata?
  end

  test "show_all_metadata?() authorizes collection administrators" do
    user    = users(:southwest)
    context = RequestContext.new(user:        user,
                                 institution: @item.institution)
    collection = @item.primary_collection
    collection.administrators.build(user: user)
    collection.save!
    policy = ItemPolicy.new(context, @item)
    assert policy.show_all_metadata?
  end

  test "show_all_metadata?() respects role limits" do
    # sysadmin user limited to an insufficient role
    user    = users(:southwest_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: @item.institution,
                                 role_limit:  Role::COLLECTION_SUBMITTER)
    policy  = ItemPolicy.new(context, @item)
    assert !policy.show_all_metadata?
  end

  # show_collections?()

  test "show_collections?() returns true with a nil user to an item that is
  neither withdrawn nor buried" do
    context = RequestContext.new(user:        nil,
                                 institution: @item.institution)
    policy = ItemPolicy.new(context, @item)
    assert policy.show_collections?
  end

  test "show_collections?() does not authorize an incorrect scope" do
    context = RequestContext.new(user:        users(:southwest_admin),
                                 institution: institutions(:northeast))
    policy  = ItemPolicy.new(context, @item)
    assert !policy.show_collections?
  end

  test "show_collections?() authorizes sysadmins" do
    user    = users(:southwest_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: @item.institution)
    policy  = ItemPolicy.new(context, @item)
    assert policy.show_collections?
  end

  test "show_collections?() authorizes unit admins" do
    user    = users(:southwest)
    context = RequestContext.new(user:        user,
                                 institution: @item.institution)
    unit    = @item.primary_collection.units.first
    unit.administrators.build(user: user)
    unit.save!
    policy = ItemPolicy.new(context, @item)
    assert policy.show_collections?
  end

  test "show_collections?() authorizes collection administrators" do
    user    = users(:southwest)
    context = RequestContext.new(user:        user,
                                 institution: @item.institution)
    collection = @item.primary_collection
    collection.administrators.build(user: user)
    collection.save!
    policy = ItemPolicy.new(context, @item)
    assert policy.show_collections?
  end

  test "show_collections?() does not authorize access to withdrawn items by
  roles beneath collection administrator" do
    @item   = items(:southwest_unit1_collection1_withdrawn)
    user    = users(:southwest)
    context = RequestContext.new(user:        user,
                                 institution: @item.institution)
    policy = ItemPolicy.new(context, @item)
    assert !policy.show_collections?
  end

  test "show_collections?() does not authorize access to buried items by
  roles beneath collection administrator" do
    @item   = items(:southwest_unit1_collection1_buried)
    user    = users(:southwest)
    context = RequestContext.new(user:        user,
                                 institution: @item.institution)
    policy = ItemPolicy.new(context, @item)
    assert !policy.show_collections?
  end

  test "show_collections?() respects role limits" do
    @item   = items(:southwest_unit1_collection1_withdrawn)
    # sysadmin user limited to an insufficient role
    user    = users(:southwest_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: @item.institution,
                                 role_limit:  Role::COLLECTION_SUBMITTER)
    policy  = ItemPolicy.new(context, @item)
    assert !policy.show_collections?
  end

  # show_embargoes?()

  test "show_embargoes?() does not authorize a nil user" do
    context = RequestContext.new(user:        nil,
                                 institution: @item.institution)
    policy = ItemPolicy.new(context, @item)
    assert !policy.show_embargoes?
  end

  test "show_embargoes?() does not authorize an incorrect scope" do
    context = RequestContext.new(user:        users(:southwest_admin),
                                 institution: institutions(:northeast))
    policy  = ItemPolicy.new(context, @item)
    assert !policy.show_embargoes?
  end

  test "show_embargoes?() is restrictive by default" do
    user    = users(:southwest)
    context = RequestContext.new(user:        user,
                                 institution: @item.institution)
    policy  = ItemPolicy.new(context, @item)
    assert !policy.show_embargoes?
  end

  test "show_embargoes?() authorizes sysadmins" do
    user    = users(:southwest_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: @item.institution)
    policy  = ItemPolicy.new(context, @item)
    assert policy.show_embargoes?
  end

  test "show_embargoes?() authorizes unit admins" do
    user    = users(:southwest)
    context = RequestContext.new(user:        user,
                                 institution: @item.institution)
    unit    = @item.primary_collection.units.first
    unit.administrators.build(user: user)
    unit.save!
    policy = ItemPolicy.new(context, @item)
    assert policy.show_embargoes?
  end

  test "show_embargoes?() authorizes collection administrators" do
    user    = users(:southwest)
    context = RequestContext.new(user:        user,
                                 institution: @item.institution)
    collection = @item.primary_collection
    collection.administrators.build(user: user)
    collection.save!
    policy = ItemPolicy.new(context, @item)
    assert policy.show_embargoes?
  end

  test "show_embargoes?() respects role limits" do
    # sysadmin user limited to an insufficient role
    user    = users(:southwest_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: @item.institution,
                                 role_limit:  Role::COLLECTION_SUBMITTER)
    policy  = ItemPolicy.new(context, @item)
    assert !policy.show_embargoes?
  end

  # show_events?()

  test "show_events?() does not authorize a nil user" do
    context = RequestContext.new(user:        nil,
                                 institution: @item.institution)
    policy = ItemPolicy.new(context, @item)
    assert !policy.show_events?
  end

  test "show_events?() does not authorize an incorrect scope" do
    context = RequestContext.new(user:        users(:southwest_admin),
                                 institution: institutions(:northeast))
    policy  = ItemPolicy.new(context, @item)
    assert !policy.show_events?
  end

  test "show_events?() is restrictive by default" do
    user    = users(:southwest)
    context = RequestContext.new(user:        user,
                                 institution: @item.institution)
    policy  = ItemPolicy.new(context, @item)
    assert !policy.show_events?
  end

  test "show_events?() authorizes sysadmins" do
    user    = users(:southwest_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: @item.institution)
    policy  = ItemPolicy.new(context, @item)
    assert policy.show_events?
  end

  test "show_events?() authorizes unit admins" do
    user    = users(:southwest)
    context = RequestContext.new(user:        user,
                                 institution: @item.institution)
    unit    = @item.primary_collection.units.first
    unit.administrators.build(user: user)
    unit.save!
    policy = ItemPolicy.new(context, @item)
    assert policy.show_events?
  end

  test "show_events?() authorizes collection administrators" do
    user       = users(:southwest)
    context    = RequestContext.new(user:        user,
                                    institution: @item.institution)
    collection = @item.primary_collection
    collection.administrators.build(user: user)
    collection.save!
    policy = ItemPolicy.new(context, @item)
    assert policy.show_events?
  end

  test "show_events?() respects role limits" do
    # sysadmin user limited to an insufficient role
    user    = users(:southwest_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: @item.institution,
                                 role_limit:  Role::COLLECTION_SUBMITTER)
    policy  = ItemPolicy.new(context, @item)
    assert !policy.show_events?
  end

  # show_metadata?()

  test "show_metadata?() returns true with a nil user to an item that is
  neither withdrawn nor buried" do
    context = RequestContext.new(user:        nil,
                                 institution: @item.institution)
    policy = ItemPolicy.new(context, @item)
    assert policy.show_metadata?
  end

  test "show_metadata?() does not authorize an incorrect scope" do
    context = RequestContext.new(user:        users(:southwest_admin),
                                 institution: institutions(:northeast))
    policy  = ItemPolicy.new(context, @item)
    assert !policy.show_metadata?
  end

  test "show_metadata?() authorizes sysadmins" do
    user    = users(:southwest_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: @item.institution)
    policy  = ItemPolicy.new(context, @item)
    assert policy.show_metadata?
  end

  test "show_metadata?() authorizes unit admins" do
    user    = users(:southwest)
    context = RequestContext.new(user:        user,
                                 institution: @item.institution)
    unit    = @item.primary_collection.units.first
    unit.administrators.build(user: user)
    unit.save!
    policy = ItemPolicy.new(context, @item)
    assert policy.show_metadata?
  end

  test "show_metadata?() authorizes collection administrators" do
    user    = users(:southwest)
    context = RequestContext.new(user:        user,
                                 institution: @item.institution)
    collection = @item.primary_collection
    collection.administrators.build(user: user)
    collection.save!
    policy = ItemPolicy.new(context, @item)
    assert policy.show_metadata?
  end

  test "show_metadata?() does not authorize access to withdrawn items by
  roles beneath collection administrator" do
    @item   = items(:southwest_unit1_collection1_withdrawn)
    user    = users(:southwest)
    context = RequestContext.new(user:        user,
                                 institution: @item.institution)
    policy = ItemPolicy.new(context, @item)
    assert !policy.show_metadata?
  end

  test "show_metadata?() does not authorize access to buried items by
  roles beneath collection administrator" do
    @item   = items(:southwest_unit1_collection1_buried)
    user    = users(:southwest)
    context = RequestContext.new(user:        user,
                                 institution: @item.institution)
    policy = ItemPolicy.new(context, @item)
    assert !policy.show_metadata?
  end

  test "show_metadata?() respects role limits" do
    @item   = items(:southwest_unit1_collection1_withdrawn)
    # sysadmin user limited to an insufficient role
    user    = users(:southwest_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: @item.institution,
                                 role_limit:  Role::COLLECTION_SUBMITTER)
    policy  = ItemPolicy.new(context, @item)
    assert !policy.show_metadata?
  end

  # show_properties?()

  test "show_properties?() does not authorize a nil user" do
    context = RequestContext.new(user:        nil,
                                 institution: @item.institution)
    policy = ItemPolicy.new(context, @item)
    assert !policy.show_properties?
  end

  test "show_properties?() does not authorize an incorrect scope" do
    context = RequestContext.new(user:        users(:southwest_admin),
                                 institution: institutions(:northeast))
    policy  = ItemPolicy.new(context, @item)
    assert !policy.show_properties?
  end

  test "show_properties?() is restrictive by default" do
    user    = users(:southwest)
    context = RequestContext.new(user:        user,
                                 institution: @item.institution)
    policy  = ItemPolicy.new(context, @item)
    assert !policy.show_properties?
  end

  test "show_properties?() authorizes sysadmins" do
    user    = users(:southwest_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: @item.institution)
    policy  = ItemPolicy.new(context, @item)
    assert policy.show_properties?
  end

  test "show_properties?() authorizes unit admins" do
    user    = users(:southwest)
    context = RequestContext.new(user:        user,
                                 institution: @item.institution)
    unit    = @item.primary_collection.units.first
    unit.administrators.build(user: user)
    unit.save!
    policy = ItemPolicy.new(context, @item)
    assert policy.show_properties?
  end

  test "show_properties?() authorizes collection administrators" do
    user    = users(:southwest)
    context = RequestContext.new(user:        user,
                                 institution: @item.institution)
    collection = @item.primary_collection
    collection.administrators.build(user: user)
    collection.save!
    policy = ItemPolicy.new(context, @item)
    assert policy.show_properties?
  end

  test "show_properties?() respects role limits" do
    # sysadmin user limited to an insufficient role
    user    = users(:southwest_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: @item.institution,
                                 role_limit:  Role::COLLECTION_SUBMITTER)
    policy  = ItemPolicy.new(context, @item)
    assert !policy.show_properties?
  end

  # statistics?()

  test "statistics?() returns true with a nil user" do
    context = RequestContext.new(user:        nil,
                                 institution: @item.institution)
    policy = ItemPolicy.new(context, @item)
    assert policy.statistics?
  end

  test "statistics?() does not authorize an incorrect scope" do
    context = RequestContext.new(user:        users(:southwest_admin),
                                 institution: institutions(:northeast))
    policy  = ItemPolicy.new(context, @item)
    assert !policy.statistics?
  end

  test "statistics?() restricts submitting items by default" do
    user    = users(:southwest)
    context = RequestContext.new(user:        user,
                                 institution: @item.institution)
    policy  = ItemPolicy.new(context, items(:southwest_unit1_collection1_submitting))
    assert !policy.statistics?
  end

  test "statistics?() restricts access to embargoed items" do
    user    = users(:southwest)
    context = RequestContext.new(user:        user,
                                 institution: @item.institution)
    policy  = ItemPolicy.new(context, @item)
    assert policy.statistics?
    @item.embargoes.build(expires_at: Time.now + 1.hour,
                          kind:       Embargo::Kind::ALL_ACCESS).save!
    assert !policy.statistics?
  end

  test "statistics?() restricts access to buried items" do
    user    = users(:southwest)
    context = RequestContext.new(user:        user,
                                 institution: @item.institution)
    item    = items(:southwest_unit1_collection1_buried)
    policy  = ItemPolicy.new(context, item)
    assert !policy.statistics?
  end

  test "statistics?() authorizes sysadmins to embargoed items" do
    user    = users(:southwest_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: @item.institution)
    policy  = ItemPolicy.new(context, items(:southwest_unit1_collection1_embargoed))
    assert policy.statistics?
  end

  test "statistics?() authorizes sysadmins to submitting items" do
    user    = users(:southwest_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: @item.institution)
    policy  = ItemPolicy.new(context, items(:southwest_unit1_collection1_submitting))
    assert policy.statistics?
  end

  test "statistics?() authorizes sysadmins to withdrawn items" do
    user    = users(:southwest_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: @item.institution)
    policy  = ItemPolicy.new(context, items(:southwest_unit1_collection1_withdrawn))
    assert policy.statistics?
  end

  test "statistics?() respects role limits" do
    # sysadmin user limited to an insufficient role
    user    = users(:southwest_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: @item.institution,
                                 role_limit:  Role::COLLECTION_SUBMITTER)
    policy  = ItemPolicy.new(context, items(:southwest_unit1_collection1_embargoed))
    assert !policy.statistics?
  end

  # undelete?()

  test "undelete?() does not authorize a nil user" do
    context = RequestContext.new(user:        nil,
                                 institution: @item.institution)
    policy = ItemPolicy.new(context, @item)
    assert !policy.undelete?
  end

  test "undelete?() does not authorize an incorrect scope" do
    context = RequestContext.new(user:        users(:southwest_admin),
                                 institution: institutions(:northeast))
    policy  = ItemPolicy.new(context, @item)
    assert !policy.undelete?
  end

  test "undelete?() authorizes sysadmins" do
    user    = users(:southwest_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: @item.institution)
    policy  = ItemPolicy.new(context, @item)
    assert policy.undelete?
  end

  test "undelete?() authorizes institution admins" do
    user    = users(:southwest_admin)
    context = RequestContext.new(user:        user,
                                 institution: @item.institution)
    policy  = ItemPolicy.new(context, @item)
    assert policy.undelete?
  end

  test "undelete?() does not authorize anyone else" do
    user    = users(:southwest)
    context = RequestContext.new(user:        user,
                                 institution: @item.institution)
    policy  = ItemPolicy.new(context, @item)
    assert !policy.undelete?
  end

  test "undelete?() respects role limits" do
    # sysadmin user limited to an insufficient role
    user    = users(:southwest_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: @item.institution,
                                 role_limit:  Role::COLLECTION_SUBMITTER)
    policy  = ItemPolicy.new(context, @item)
    assert !policy.undelete?
  end

  # update?()

  test "update?() does not authorize a nil user" do
    context = RequestContext.new(user:        nil,
                                 institution: @item.institution)
    policy = ItemPolicy.new(context, @item)
    assert !policy.update?
  end

  test "update?() does not authorize an incorrect scope" do
    context = RequestContext.new(user:        users(:southwest_admin),
                                 institution: institutions(:northeast))
    policy  = ItemPolicy.new(context, @item)
    assert !policy.update?
  end

  test "update?() does not authorize non-sysadmins" do
    user    = users(:southwest)
    context = RequestContext.new(user:        user,
                                 institution: @item.institution)
    policy  = ItemPolicy.new(context, @item)
    assert !policy.update?
  end

  test "update?() authorizes sysadmins" do
    user    = users(:southwest_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: @item.institution)
    policy  = ItemPolicy.new(context, @item)
    assert policy.update?
  end

  test "update?() authorizes the submission owner if the item is submitting" do
    user    = users(:southwest)
    context = RequestContext.new(user:        user,
                                 institution: @item.institution)
    @item.submitter = user
    @item.stage     = Item::Stages::SUBMITTING
    policy = ItemPolicy.new(context, @item)
    assert policy.update?
  end

  test "update?() does not authorize the submission owner if the item is not submitting" do
    user       = users(:southwest)
    context    = RequestContext.new(user:        user,
                                    institution: @item.institution)
    collection = @item.primary_collection
    collection.submitting_users << user
    collection.save!
    @item.submitter = user
    @item.stage     = Item::Stages::APPROVED
    policy = ItemPolicy.new(context, @item)
    assert !policy.update?
  end

  test "update?() authorizes administrators of the submission's collection" do
    doing_user = users(:southwest)
    context    = RequestContext.new(user:        doing_user,
                                    institution: doing_user.institution)
    collection = collections(:uiuc_collection1)
    collection.administering_users << doing_user
    collection.save!
    @item.submitter          = users(:southwest) # somebody else
    @item.primary_collection = collection

    policy = ItemPolicy.new(context, @item)
    assert policy.update?
  end

  test "update?() authorizes admins of the submission's collection's unit" do
    doing_user = users(:southwest)
    context    = RequestContext.new(user:        doing_user,
                                    institution: doing_user.institution)
    collection               = collections(:uiuc_collection1)
    unit                     = collection.primary_unit
    unit.administering_users << doing_user
    unit.save!
    @item.submitter          = users(:southwest) # somebody else
    @item.primary_collection = collection

    policy = ItemPolicy.new(context, @item)
    assert policy.update?
  end

  test "update?() does not authorize anyone else" do
    user    = users(:southwest)
    context = RequestContext.new(user:        user,
                                 institution: @item.institution)
    policy  = ItemPolicy.new(context, @item)
    assert !policy.update?
  end

  test "update?() respects role limits" do
    # sysadmin user limited to an insufficient role
    user    = users(:southwest_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: @item.institution,
                                 role_limit:  Role::COLLECTION_SUBMITTER)
    policy  = ItemPolicy.new(context, @item)
    assert !policy.update?
  end

  # upload_bitstreams?()

  test "upload_bitstreams?() does not authorize a nil user" do
    context = RequestContext.new(user:        nil,
                                 institution: @item.institution)
    policy = ItemPolicy.new(context, @item)
    assert !policy.upload_bitstreams?
  end

  test "upload_bitstreams?() does not authorize an incorrect scope" do
    context = RequestContext.new(user:        users(:southwest_admin),
                                 institution: institutions(:northeast))
    policy  = ItemPolicy.new(context, @item)
    assert !policy.upload_bitstreams?
  end

  test "upload_bitstreams?() is restrictive by default" do
    user    = users(:southwest)
    context = RequestContext.new(user:        user,
                                 institution: @item.institution)
    policy  = ItemPolicy.new(context, @item)
    assert !policy.upload_bitstreams?
  end

  test "upload_bitstreams?() authorizes sysadmins" do
    user    = users(:southwest_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: @item.institution)
    policy  = ItemPolicy.new(context, @item)
    assert policy.upload_bitstreams?
  end

  test "upload_bitstreams?() authorizes unit admins" do
    user    = users(:southwest)
    context = RequestContext.new(user:        user,
                                 institution: @item.institution)
    unit    = @item.primary_collection.units.first
    unit.administrators.build(user: user)
    unit.save!
    policy = ItemPolicy.new(context, @item)
    assert policy.upload_bitstreams?
  end

  test "upload_bitstreams?() authorizes collection administrators" do
    user       = users(:southwest)
    context    = RequestContext.new(user:        user,
                                    institution: @item.institution)
    collection = @item.primary_collection
    collection.administrators.build(user: user)
    collection.save!
    policy = ItemPolicy.new(context, @item)
    assert policy.upload_bitstreams?
  end

  test "upload_bitstreams?() respects role limits" do
    # sysadmin user limited to an insufficient role
    user    = users(:southwest_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: @item.institution,
                                 role_limit:  Role::COLLECTION_SUBMITTER)
    policy  = ItemPolicy.new(context, @item)
    assert !policy.upload_bitstreams?
  end

  # withdraw?()

  test "withdraw?() does not authorize a nil user" do
    context = RequestContext.new(user:        nil,
                                 institution: @item.institution)
    policy = ItemPolicy.new(context, @item)
    assert !policy.withdraw?
  end

  test "withdraw?() does not authorize an incorrect scope" do
    context = RequestContext.new(user:        users(:southwest_admin),
                                 institution: institutions(:northeast))
    policy  = ItemPolicy.new(context, @item)
    assert !policy.withdraw?
  end

  test "withdraw?() does not authorize non-unit-admins" do
    user    = users(:southwest)
    context = RequestContext.new(user:        user,
                                 institution: @item.institution)
    policy  = ItemPolicy.new(context, @item)
    assert !policy.withdraw?
  end

  test "withdraw?() authorizes unit admins" do
    user = users(:southwest)
    unit = @item.effective_primary_unit
    unit.administering_users << user
    unit.save!
    context = RequestContext.new(user:        user,
                                 institution: @item.institution)
    policy = ItemPolicy.new(context, @item)
    assert policy.withdraw?
  end

  test "withdraw?() respects role limits" do
    # sysadmin user limited to an insufficient role
    user    = users(:southwest_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: @item.institution,
                                 role_limit:  Role::COLLECTION_SUBMITTER)
    policy  = ItemPolicy.new(context, @item)
    assert !policy.withdraw?
  end

end
