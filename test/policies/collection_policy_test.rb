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
    user    = users(:norights)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    collection2 = collections(:described)
    policy      = CollectionPolicy.new(context, @collection)
    assert !policy.change_parent?(collection2.id)
  end

  test "change_parent?() authorizes sysadmins" do
    user    = users(:local_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    collection2 = collections(:described)
    policy      = CollectionPolicy.new(context, @collection)
    assert policy.change_parent?(collection2.id)
  end

  test "change_parent?() respects role limits" do
    # sysadmin user limited to an insufficient role
    user    = users(:local_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::LOGGED_IN)
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
    user    = users(:norights)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::NO_LIMIT)
    policy  = CollectionPolicy.new(context, @collection)
    assert policy.children?
  end

  # create?()

  test "create?() returns false with a nil user" do
    policy = CollectionPolicy.new(nil, @collection)
    assert !policy.create?
  end

  test "create?() is restrictive by default" do
    user    = users(:norights)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = CollectionPolicy.new(context, @collection)
    assert !policy.create?
  end

  test "create?() authorizes sysadmins" do
    user    = users(:local_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = CollectionPolicy.new(context, @collection)
    assert policy.create?
  end

  test "create?() authorizes unit admins" do
    user    = users(:norights)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)

    unit = @collection.units.first
    unit.administrators.build(user: user)
    unit.save!

    policy = CollectionPolicy.new(context, @collection)
    assert policy.create?
  end

  test "create?() authorizes collection managers" do
    user    = users(:norights)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)

    @collection.managing_users << user
    @collection.save!

    policy = CollectionPolicy.new(context, @collection)
    assert policy.create?
  end

  test "create?() works with class objects" do
    user    = users(:norights)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = CollectionPolicy.new(context, Collection)
    assert !policy.create?
  end

  test "create?() respects role limits" do
    # sysadmin user limited to an insufficient role
    user    = users(:local_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::COLLECTION_SUBMITTER)
    policy  = CollectionPolicy.new(context, @collection)
    assert !policy.create?
  end

  # delete?()

  test "delete?() returns false with a nil user" do
    policy = CollectionPolicy.new(nil, @collection)
    assert !policy.delete?
  end

  test "delete?() is restrictive by default" do
    user    = users(:norights)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = CollectionPolicy.new(context, @collection)
    assert !policy.delete?
  end

  test "delete?() authorizes sysadmins" do
    user    = users(:local_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = CollectionPolicy.new(context, @collection)
    assert policy.delete?
  end

  test "delete?() respects role limits" do
    # sysadmin user limited to an insufficient role
    user    = users(:local_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::COLLECTION_SUBMITTER)
    policy  = CollectionPolicy.new(context, @collection)
    assert !policy.delete?
  end

  # edit_collection_membership?()

  test "edit_collection_membership?() returns false with a nil user" do
    policy = CollectionPolicy.new(nil, @collection)
    assert !policy.edit_collection_membership?
  end

  test "edit_collection_membership?() is restrictive by default" do
    user    = users(:norights)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = CollectionPolicy.new(context, @collection)
    assert !policy.edit_collection_membership?
  end

  test "edit_collection_membership?() authorizes sysadmins" do
    user    = users(:local_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = CollectionPolicy.new(context, @collection)
    assert policy.edit_collection_membership?
  end

  test "edit_collection_membership?() respects role limits" do
    # sysadmin user limited to an insufficient role
    user    = users(:local_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::COLLECTION_SUBMITTER)
    policy  = CollectionPolicy.new(context, @collection)
    assert !policy.edit_collection_membership?
  end

  # edit_managers?()

  test "edit_managers?() returns false with a nil user" do
    policy = CollectionPolicy.new(nil, @collection)
    assert !policy.edit_managers?
  end

  test "edit_managers?() is restrictive by default" do
    user    = users(:norights)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = CollectionPolicy.new(context, @collection)
    assert !policy.edit_managers?
  end

  test "edit_managers?() authorizes sysadmins" do
    user    = users(:local_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy   = CollectionPolicy.new(context, @collection)
    assert policy.edit_managers?
  end

  test "edit_managers?() respects role limits" do
    # sysadmin user limited to an insufficient role
    user    = users(:local_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::COLLECTION_SUBMITTER)
    policy  = CollectionPolicy.new(context, @collection)
    assert !policy.edit_managers?
  end

  # edit_properties?()

  test "edit_properties?() returns false with a nil user" do
    policy = CollectionPolicy.new(nil, @collection)
    assert !policy.edit_properties?
  end

  test "edit_properties?() is restrictive by default" do
    user    = users(:norights)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = CollectionPolicy.new(context, @collection)
    assert !policy.edit_properties?
  end

  test "edit_properties?() authorizes sysadmins" do
    user    = users(:local_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy   = CollectionPolicy.new(context, @collection)
    assert policy.edit_properties?
  end

  test "edit_properties?() respects role limits" do
    # sysadmin user limited to an insufficient role
    user    = users(:local_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::COLLECTION_SUBMITTER)
    policy  = CollectionPolicy.new(context, @collection)
    assert !policy.edit_properties?
  end

  # edit_submitters?()

  test "edit_submitters?() returns false with a nil user" do
    policy = CollectionPolicy.new(nil, @collection)
    assert !policy.edit_submitters?
  end

  test "edit_submitters?() is restrictive by default" do
    user    = users(:norights)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = CollectionPolicy.new(context, @collection)
    assert !policy.edit_submitters?
  end

  test "edit_submitters?() authorizes sysadmins" do
    user    = users(:local_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy   = CollectionPolicy.new(context, @collection)
    assert policy.edit_submitters?
  end

  test "edit_submitters?() respects role limits" do
    # sysadmin user limited to an insufficient role
    user    = users(:local_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::COLLECTION_SUBMITTER)
    policy  = CollectionPolicy.new(context, @collection)
    assert !policy.edit_submitters?
  end

  # edit_unit_membership?()

  test "edit_unit_membership?() returns false with a nil user" do
    policy = CollectionPolicy.new(nil, @collection)
    assert !policy.edit_unit_membership?
  end

  test "edit_unit_membership?() is restrictive by default" do
    user    = users(:norights)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = CollectionPolicy.new(context, @collection)
    assert !policy.edit_unit_membership?
  end

  test "edit_unit_membership?() authorizes sysadmins" do
    user    = users(:local_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = CollectionPolicy.new(context, @collection)
    assert policy.edit_unit_membership?
  end

  test "edit_unit_membership?() respects role limits" do
    # sysadmin user limited to an insufficient role
    user    = users(:local_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::COLLECTION_SUBMITTER)
    policy  = CollectionPolicy.new(context, @collection)
    assert !policy.edit_unit_membership?
  end

  # index?()

  test "index?() returns true with a nil user" do
    policy = CollectionPolicy.new(nil, Collection)
    assert policy.index?
  end

  test "index?() authorizes everyone" do
    user    = users(:norights)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = CollectionPolicy.new(context, Collection)
    assert policy.index?
  end

  # item_download_counts?()

  test "item_download_counts?() returns true with a nil user" do
    policy = CollectionPolicy.new(nil, @collection)
    assert policy.item_download_counts?
  end

  test "item_download_counts?() authorizes everyone" do
    user    = users(:norights)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = CollectionPolicy.new(context, @collection)
    assert policy.item_download_counts?
  end

  # item_results?()

  test "item_results?() returns true with a nil user" do
    policy = CollectionPolicy.new(nil, @collection)
    assert policy.item_results?
  end

  test "item_results?() authorizes everyone" do
    user    = users(:norights)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = CollectionPolicy.new(context, @collection)
    assert policy.item_results?
  end

  # new?()

  test "new?() returns false with a nil user" do
    policy = CollectionPolicy.new(nil, @collection)
    assert !policy.new?
  end

  test "new?() is restrictive by default" do
    user    = users(:norights)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = CollectionPolicy.new(context, @collection)
    assert !policy.new?
  end

  test "new?() authorizes sysadmins" do
    user    = users(:local_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = CollectionPolicy.new(context, @collection)
    assert policy.new?
  end

  test "new?() works with class objects" do
    user    = users(:norights)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = CollectionPolicy.new(context, Collection)
    assert !policy.new?
  end

  test "new?() respects role limits" do
    # sysadmin user limited to an insufficient role
    user    = users(:local_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::COLLECTION_SUBMITTER)
    policy  = CollectionPolicy.new(context, @collection)
    assert !policy.new?
  end

  # show?()

  test "show?() returns true with a nil user" do
    policy = CollectionPolicy.new(nil, @collection)
    assert policy.show?
  end

  test "show?() authorizes everyone" do
    user    = users(:norights)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = CollectionPolicy.new(context, @collection)
    assert policy.show?
  end

  # show_access?()

  test "show_access?() returns false with a nil user" do
    policy = CollectionPolicy.new(nil, @collection)
    assert !policy.show_access?
  end

  test "show_access?() is restrictive by default" do
    user    = users(:norights)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = CollectionPolicy.new(context, @collection)
    assert !policy.show_access?
  end

  test "show_access?() authorizes sysadmins" do
    user    = users(:local_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = CollectionPolicy.new(context, @collection)
    assert policy.show_access?
  end

  test "show_access?() respects role limits" do
    # sysadmin user limited to an insufficient role
    user    = users(:local_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::COLLECTION_SUBMITTER)
    policy  = CollectionPolicy.new(context, @collection)
    assert !policy.show_access?
  end

  # show_collections?()

  test "show_collections?() returns true with a nil user" do
    policy = CollectionPolicy.new(nil, @collection)
    assert policy.show_collections?
  end

  test "show_collections?() authorizes everyone" do
    user    = users(:norights)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = CollectionPolicy.new(context, @collection)
    assert policy.show_collections?
  end

  # show_items?()

  test "show_items?() returns true with a nil user" do
    policy = CollectionPolicy.new(nil, @collection)
    assert policy.show_items?
  end

  test "show_items?() authorizes everyone" do
    user    = users(:norights)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = CollectionPolicy.new(context, @collection)
    assert policy.show_items?
  end

  # show_properties?()

  test "show_properties?() returns true with a nil user" do
    policy = CollectionPolicy.new(nil, @collection)
    assert policy.show_properties?
  end

  test "show_properties?() authorizes everyone" do
    user    = users(:norights)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = CollectionPolicy.new(context, @collection)
    assert policy.show_properties?
  end

  # show_review_submissions?()

  test "show_review_submissions?() returns false with a nil user" do
    policy = CollectionPolicy.new(nil, @collection)
    assert !policy.show_review_submissions?
  end

  test "show_review_submissions?() is restrictive by default" do
    user    = users(:norights)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = CollectionPolicy.new(context, @collection)
    assert !policy.show_review_submissions?
  end

  test "show_review_submissions?() authorizes sysadmins" do
    user    = users(:local_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = CollectionPolicy.new(context, @collection)
    assert policy.show_review_submissions?
  end

  test "show_review_submissions?() authorizes collection managers" do
    user = users(:norights)
    user.managing_collections << @collection
    user.save!
    user    = users(:norights)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = CollectionPolicy.new(context, @collection)
    assert policy.show_review_submissions?
  end

  test "show_review_submissions?() respects role limits" do
    # sysadmin user limited to an insufficient role
    user    = users(:local_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::LOGGED_IN)
    policy  = CollectionPolicy.new(context, @collection)
    assert !policy.show_review_submissions?
  end

  # show_statistics?()

  test "show_statistics?() returns true with a nil user" do
    policy = CollectionPolicy.new(nil, @collection)
    assert policy.show_statistics?
  end

  test "show_statistics?() authorizes everyone" do
    user    = users(:norights)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = CollectionPolicy.new(context, @collection)
    assert policy.show_statistics?
  end

  # show_units?()

  test "show_units?() returns true with a nil user" do
    policy = CollectionPolicy.new(nil, @collection)
    assert policy.show_units?
  end

  test "show_units?() authorizes everyone" do
    user    = users(:norights)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = CollectionPolicy.new(context, @collection)
    assert policy.show_units?
  end

  # statistics_by_range?()

  test "statistics_by_range?() returns true with a nil user" do
    policy = CollectionPolicy.new(nil, @collection)
    assert policy.statistics_by_range?
  end

  test "statistics_by_range?() authorizes everyone" do
    user    = users(:norights)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = CollectionPolicy.new(context, @collection)
    assert policy.statistics_by_range?
  end

  # submit_item?()

  test "submit_item?() returns false with a nil user" do
    policy = CollectionPolicy.new(nil, @collection)
    assert !policy.submit_item?
  end

  test "submit_item?() is restrictive by default" do
    user    = users(:norights)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = CollectionPolicy.new(context, @collection)
    assert !policy.submit_item?
  end

  test "submit_item?() authorizes sysadmins" do
    user    = users(:local_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = CollectionPolicy.new(context, @collection)
    assert policy.submit_item?
  end

  test "submit_item?() authorizes unit admins" do
    user    = users(:norights)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)

    unit = @collection.units.first
    unit.administrators.build(user: user)
    unit.save!

    policy = CollectionPolicy.new(context, @collection)
    assert policy.submit_item?
  end

  test "submit_item?() authorizes collection managers" do
    user    = users(:norights)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)

    @collection.managing_users << user
    @collection.save!

    policy = CollectionPolicy.new(context, @collection)
    assert policy.submit_item?
  end

  test "submit_item?() authorizes collection submitters" do
    user    = users(:norights)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)

    @collection.submitting_users << user
    @collection.save!

    policy = CollectionPolicy.new(context, @collection)
    assert policy.submit_item?
  end

  test "submit_item?() respects role limits" do
    # sysadmin user limited to an insufficient role
    user    = users(:local_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::LOGGED_IN)
    policy  = CollectionPolicy.new(context, @collection)
    assert !policy.submit_item?
  end

  # undelete?()

  test "undelete?() returns false with a nil user" do
    policy = CollectionPolicy.new(nil, @collection)
    assert !policy.undelete?
  end

  test "undelete?() is restrictive by default" do
    user    = users(:norights)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = CollectionPolicy.new(context, @collection)
    assert !policy.undelete?
  end

  test "undelete?() authorizes sysadmins" do
    user    = users(:local_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = CollectionPolicy.new(context, @collection)
    assert policy.undelete?
  end

  test "undelete?() respects role limits" do
    # sysadmin user limited to an insufficient role
    user    = users(:local_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::COLLECTION_SUBMITTER)
    policy  = CollectionPolicy.new(context, @collection)
    assert !policy.undelete?
  end

  # update?()

  test "update?() returns false with a nil user" do
    policy = CollectionPolicy.new(nil, @collection)
    assert !policy.update?
  end

  test "update?() is restrictive by default" do
    user    = users(:norights)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = CollectionPolicy.new(context, @collection)
    assert !policy.update?
  end

  test "update?() authorizes sysadmins" do
    user    = users(:local_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = CollectionPolicy.new(context, @collection)
    assert policy.update?
  end

  test "update?() authorizes unit admins" do
    user    = users(:norights)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)

    unit = @collection.units.first
    unit.administrators.build(user: user)
    unit.save!

    policy = CollectionPolicy.new(context, @collection)
    assert policy.update?
  end

  test "update?() authorizes collection managers" do
    user    = users(:norights)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)

    @collection.managing_users << user
    @collection.save!

    policy = CollectionPolicy.new(context, @collection)
    assert policy.update?
  end

  test "update?() respects role limits" do
    # sysadmin user limited to an insufficient role
    user    = users(:local_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::COLLECTION_SUBMITTER)
    policy  = CollectionPolicy.new(context, @collection)
    assert !policy.update?
  end

end
