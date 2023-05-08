require 'test_helper'

class CollectionPolicyTest < ActiveSupport::TestCase

  setup do
    @collection = collections(:southwest_unit1_collection1)
  end

  # all_files?()

  test "all_files?() returns false with a nil user" do
    context = RequestContext.new(user:        nil,
                                 institution: @collection.institution)
    policy = CollectionPolicy.new(context, @collection)
    assert !policy.all_files?
  end

  test "all_files?() does not authorize an incorrect scope" do
    context = RequestContext.new(user:        users(:southwest_admin),
                                 institution: institutions(:northeast))
    policy  = CollectionPolicy.new(context, @collection)
    assert !policy.all_files?
  end

  test "all_files?() is restrictive by default" do
    user    = users(:southwest)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = CollectionPolicy.new(context, @collection)
    assert !policy.all_files?
  end

  test "all_files?() authorizes sysadmins" do
    user    = users(:southwest_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = CollectionPolicy.new(context, @collection)
    assert policy.all_files?
  end

  test "all_files?() authorizes collection administrators" do
    user = users(:southwest)
    user.administering_collections << @collection
    user.save!
    user    = users(:southwest)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = CollectionPolicy.new(context, @collection)
    assert policy.all_files?
  end

  test "all_files?() respects role limits" do
    # sysadmin user limited to an insufficient role
    user    = users(:southwest_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::LOGGED_IN)
    policy  = CollectionPolicy.new(context, @collection)
    assert !policy.all_files?
  end

  # change_parent?()

  test "change_parent?() returns false with a nil user" do
    context = RequestContext.new(user:        nil,
                                 institution: @collection.institution)
    collection2 = collections(:southwest_unit1_collection2)
    policy      = CollectionPolicy.new(context, @collection)
    assert !policy.change_parent?(collection2.id)
  end

  test "change_parent?() does not authorize an incorrect scope" do
    context = RequestContext.new(user:        users(:southwest_admin),
                                 institution: institutions(:northeast))
    collection2 = collections(:southwest_unit1_collection2)
    policy  = CollectionPolicy.new(context, @collection)
    assert !policy.change_parent?(collection2.id)
  end

  test "change_parent?() is restrictive by default" do
    user    = users(:southwest)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    collection2 = collections(:uiuc_described)
    policy      = CollectionPolicy.new(context, @collection)
    assert !policy.change_parent?(collection2.id)
  end

  test "change_parent?() authorizes sysadmins" do
    user    = users(:southwest_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    collection2 = collections(:uiuc_described)
    policy      = CollectionPolicy.new(context, @collection)
    assert policy.change_parent?(collection2.id)
  end

  test "change_parent?() respects role limits" do
    # sysadmin user limited to an insufficient role
    user    = users(:southwest_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::LOGGED_IN)
    collection2 = collections(:uiuc_described)
    policy      = CollectionPolicy.new(context, @collection)
    assert !policy.change_parent?(collection2.id)
  end

  # children?()

  test "children?() returns true with a nil user" do
    context = RequestContext.new(user:        nil,
                                 institution: @collection.institution)
    policy = CollectionPolicy.new(context, @collection)
    assert policy.children?
  end

  test "children?() does not authorize an incorrect scope" do
    context = RequestContext.new(user:        users(:southwest_admin),
                                 institution: institutions(:northeast))
    policy  = CollectionPolicy.new(context, @collection)
    assert !policy.children?
  end

  test "children?() authorizes everyone" do
    user    = users(:southwest)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::NO_LIMIT)
    policy  = CollectionPolicy.new(context, @collection)
    assert policy.children?
  end

  # create?()

  test "create?() returns false with a nil user" do
    context = RequestContext.new(user:        nil,
                                 institution: @collection.institution)
    policy = CollectionPolicy.new(context, @collection)
    assert !policy.create?
  end

  test "create?() does not authorize an incorrect scope" do
    context = RequestContext.new(user:        users(:southwest_admin),
                                 institution: institutions(:northeast))
    policy  = CollectionPolicy.new(context, @collection)
    assert !policy.create?
  end

  test "create?() is restrictive by default" do
    user    = users(:southwest)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = CollectionPolicy.new(context, @collection)
    assert !policy.create?
  end

  test "create?() authorizes sysadmins" do
    user    = users(:southwest_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = CollectionPolicy.new(context, @collection)
    assert policy.create?
  end

  test "create?() authorizes unit admins" do
    user    = users(:southwest)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)

    unit = @collection.units.first
    unit.administrators.build(user: user)
    unit.save!

    policy = CollectionPolicy.new(context, @collection)
    assert policy.create?
  end

  test "create?() authorizes collection administrators" do
    user    = users(:southwest)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)

    @collection.administering_users << user
    @collection.save!

    policy = CollectionPolicy.new(context, @collection)
    assert policy.create?
  end

  test "create?() works with class objects" do
    user    = users(:southwest)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = CollectionPolicy.new(context, Collection)
    assert !policy.create?
  end

  test "create?() respects role limits" do
    # sysadmin user limited to an insufficient role
    user    = users(:southwest_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::COLLECTION_SUBMITTER)
    policy  = CollectionPolicy.new(context, @collection)
    assert !policy.create?
  end

  # delete?()

  test "delete?() returns false with a nil user" do
    context = RequestContext.new(user:        nil,
                                 institution: @collection.institution)
    policy = CollectionPolicy.new(context, @collection)
    assert !policy.delete?
  end

  test "delete?() does not authorize an incorrect scope" do
    context = RequestContext.new(user:        users(:southwest_admin),
                                 institution: institutions(:northeast))
    policy  = CollectionPolicy.new(context, @collection)
    assert !policy.delete?
  end

  test "delete?() is restrictive by default" do
    user    = users(:southwest)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = CollectionPolicy.new(context, @collection)
    assert !policy.delete?
  end

  test "delete?() authorizes sysadmins" do
    user    = users(:southwest_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = CollectionPolicy.new(context, @collection)
    assert policy.delete?
  end

  test "delete?() authorizes institution admins" do
    user    = users(:southwest_admin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = CollectionPolicy.new(context, @collection)
    assert policy.delete?
  end

  test "delete?() respects role limits" do
    # sysadmin user limited to an insufficient role
    user    = users(:southwest_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::COLLECTION_SUBMITTER)
    policy  = CollectionPolicy.new(context, @collection)
    assert !policy.delete?
  end

  # edit_collection_membership?()

  test "edit_collection_membership?() returns false with a nil user" do
    context = RequestContext.new(user:        nil,
                                 institution: @collection.institution)
    policy = CollectionPolicy.new(context, @collection)
    assert !policy.edit_collection_membership?
  end

  test "edit_collection_membership?() does not authorize an incorrect scope" do
    context = RequestContext.new(user:        users(:southwest_admin),
                                 institution: institutions(:northeast))
    policy  = CollectionPolicy.new(context, @collection)
    assert !policy.edit_collection_membership?
  end

  test "edit_collection_membership?() is restrictive by default" do
    user    = users(:southwest)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = CollectionPolicy.new(context, @collection)
    assert !policy.edit_collection_membership?
  end

  test "edit_collection_membership?() authorizes sysadmins" do
    user    = users(:southwest_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = CollectionPolicy.new(context, @collection)
    assert policy.edit_collection_membership?
  end

  test "edit_collection_membership?() respects role limits" do
    # sysadmin user limited to an insufficient role
    user    = users(:southwest_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::COLLECTION_SUBMITTER)
    policy  = CollectionPolicy.new(context, @collection)
    assert !policy.edit_collection_membership?
  end

  # edit_administering_groups?()

  test "edit_administering_groups?() returns false with a nil user" do
    context = RequestContext.new(user:        nil,
                                 institution: @collection.institution)
    policy = CollectionPolicy.new(context, @collection)
    assert !policy.edit_administering_groups?
  end

  test "edit_administering_groups?() does not authorize an incorrect scope" do
    context = RequestContext.new(user:        users(:southwest_admin),
                                 institution: institutions(:northeast))
    policy  = CollectionPolicy.new(context, @collection)
    assert !policy.edit_administering_groups?
  end

  test "edit_administering_groups?() is restrictive by default" do
    user    = users(:southwest)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = CollectionPolicy.new(context, @collection)
    assert !policy.edit_administering_groups?
  end

  test "edit_administering_groups?() authorizes sysadmins" do
    user    = users(:southwest_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy   = CollectionPolicy.new(context, @collection)
    assert policy.edit_administering_groups?
  end

  test "edit_administering_groups?() respects role limits" do
    # sysadmin user limited to an insufficient role
    user    = users(:southwest_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::COLLECTION_SUBMITTER)
    policy  = CollectionPolicy.new(context, @collection)
    assert !policy.edit_administering_groups?
  end

  # edit_administering_users?()

  test "edit_administering_users?() returns false with a nil user" do
    context = RequestContext.new(user:        nil,
                                 institution: @collection.institution)
    policy = CollectionPolicy.new(context, @collection)
    assert !policy.edit_administering_users?
  end

  test "edit_administering_users?() does not authorize an incorrect scope" do
    context = RequestContext.new(user:        users(:southwest_admin),
                                 institution: institutions(:northeast))
    policy  = CollectionPolicy.new(context, @collection)
    assert !policy.edit_administering_users?
  end

  test "edit_administering_users?() is restrictive by default" do
    user    = users(:southwest)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = CollectionPolicy.new(context, @collection)
    assert !policy.edit_administering_users?
  end

  test "edit_administering_users?() authorizes sysadmins" do
    user    = users(:southwest_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy   = CollectionPolicy.new(context, @collection)
    assert policy.edit_administering_users?
  end

  test "edit_administering_users?() respects role limits" do
    # sysadmin user limited to an insufficient role
    user    = users(:southwest_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::COLLECTION_SUBMITTER)
    policy  = CollectionPolicy.new(context, @collection)
    assert !policy.edit_administering_users?
  end

  # edit_properties?()

  test "edit_properties?() returns false with a nil user" do
    context = RequestContext.new(user:        nil,
                                 institution: @collection.institution)
    policy = CollectionPolicy.new(context, @collection)
    assert !policy.edit_properties?
  end

  test "edit_properties?() does not authorize an incorrect scope" do
    context = RequestContext.new(user:        users(:southwest_admin),
                                 institution: institutions(:northeast))
    policy  = CollectionPolicy.new(context, @collection)
    assert !policy.edit_properties?
  end

  test "edit_properties?() is restrictive by default" do
    user    = users(:southwest)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = CollectionPolicy.new(context, @collection)
    assert !policy.edit_properties?
  end

  test "edit_properties?() authorizes sysadmins" do
    user    = users(:southwest_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy   = CollectionPolicy.new(context, @collection)
    assert policy.edit_properties?
  end

  test "edit_properties?() respects role limits" do
    # sysadmin user limited to an insufficient role
    user    = users(:southwest_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::COLLECTION_SUBMITTER)
    policy  = CollectionPolicy.new(context, @collection)
    assert !policy.edit_properties?
  end

  # edit_submitters?()

  test "edit_submitters?() returns false with a nil user" do
    context = RequestContext.new(user:        nil,
                                 institution: @collection.institution)
    policy = CollectionPolicy.new(context, @collection)
    assert !policy.edit_submitters?
  end

  test "edit_submitters?() does not authorize an incorrect scope" do
    context = RequestContext.new(user:        users(:southwest_admin),
                                 institution: institutions(:northeast))
    policy  = CollectionPolicy.new(context, @collection)
    assert !policy.edit_submitters?
  end

  test "edit_submitters?() is restrictive by default" do
    user    = users(:southwest)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = CollectionPolicy.new(context, @collection)
    assert !policy.edit_submitters?
  end

  test "edit_submitters?() authorizes sysadmins" do
    user    = users(:southwest_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy   = CollectionPolicy.new(context, @collection)
    assert policy.edit_submitters?
  end

  test "edit_submitters?() respects role limits" do
    # sysadmin user limited to an insufficient role
    user    = users(:southwest_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::COLLECTION_SUBMITTER)
    policy  = CollectionPolicy.new(context, @collection)
    assert !policy.edit_submitters?
  end

  # edit_unit_membership?()

  test "edit_unit_membership?() returns false with a nil user" do
    context = RequestContext.new(user:        nil,
                                 institution: @collection.institution)
    policy = CollectionPolicy.new(context, @collection)
    assert !policy.edit_unit_membership?
  end

  test "edit_unit_membership?() does not authorize an incorrect scope" do
    context = RequestContext.new(user:        users(:southwest_admin),
                                 institution: institutions(:northeast))
    policy  = CollectionPolicy.new(context, @collection)
    assert !policy.edit_unit_membership?
  end

  test "edit_unit_membership?() is restrictive by default" do
    user    = users(:southwest)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = CollectionPolicy.new(context, @collection)
    assert !policy.edit_unit_membership?
  end

  test "edit_unit_membership?() authorizes sysadmins" do
    user    = users(:southwest_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = CollectionPolicy.new(context, @collection)
    assert policy.edit_unit_membership?
  end

  test "edit_unit_membership?() respects role limits" do
    # sysadmin user limited to an insufficient role
    user    = users(:southwest_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::COLLECTION_SUBMITTER)
    policy  = CollectionPolicy.new(context, @collection)
    assert !policy.edit_unit_membership?
  end

  # export_items?()

  test "export_items?() returns false with a nil user" do
    context = RequestContext.new(user:        nil,
                                 institution: @collection.institution)
    policy = CollectionPolicy.new(context, @collection)
    assert !policy.export_items?
  end

  test "export_items?() does not authorize an incorrect scope" do
    context = RequestContext.new(user:        users(:southwest_admin),
                                 institution: institutions(:northeast))
    policy  = CollectionPolicy.new(context, @collection)
    assert !policy.export_items?
  end

  test "export_items?() is restrictive by default" do
    user    = users(:southwest)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = CollectionPolicy.new(context, @collection)
    assert !policy.export_items?
  end

  test "export_items?() authorizes sysadmins" do
    user    = users(:southwest_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = CollectionPolicy.new(context, @collection)
    assert policy.export_items?
  end

  test "export_items?() authorizes collection administrators" do
    user = users(:southwest)
    user.administering_collections << @collection
    user.save!
    user    = users(:southwest)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = CollectionPolicy.new(context, @collection)
    assert policy.export_items?
  end

  test "export_items?() respects role limits" do
    # sysadmin user limited to an insufficient role
    user    = users(:southwest_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::LOGGED_IN)
    policy  = CollectionPolicy.new(context, @collection)
    assert !policy.export_items?
  end

  # index?()

  test "index?() returns true with a nil user" do
    context = RequestContext.new(user:        nil,
                                 institution: @collection.institution)
    policy = CollectionPolicy.new(context, Collection)
    assert policy.index?
  end

  test "index?() does not authorize an incorrect scope" do
    context = RequestContext.new(user:        users(:southwest_admin),
                                 institution: institutions(:northeast))
    policy  = CollectionPolicy.new(context, @collection)
    assert !policy.index?
  end

  test "index?() authorizes everyone" do
    user    = users(:southwest)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = CollectionPolicy.new(context, Collection)
    assert policy.index?
  end

  # item_download_counts?()

  test "item_download_counts?() returns true with a nil user" do
    context = RequestContext.new(user:        nil,
                                 institution: @collection.institution)
    policy = CollectionPolicy.new(context, @collection)
    assert policy.item_download_counts?
  end

  test "item_download_counts?() does not authorize an incorrect scope" do
    context = RequestContext.new(user:        users(:southwest_admin),
                                 institution: institutions(:northeast))
    policy  = CollectionPolicy.new(context, @collection)
    assert !policy.item_download_counts?
  end

  test "item_download_counts?() authorizes everyone" do
    user    = users(:southwest)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = CollectionPolicy.new(context, @collection)
    assert policy.item_download_counts?
  end

  # item_results?()

  test "item_results?() returns true with a nil user" do
    context = RequestContext.new(user:        nil,
                                 institution: @collection.institution)
    policy = CollectionPolicy.new(context, @collection)
    assert policy.item_results?
  end

  test "item_results?() does not authorize an incorrect scope" do
    context = RequestContext.new(user:        users(:southwest_admin),
                                 institution: institutions(:northeast))
    policy  = CollectionPolicy.new(context, @collection)
    assert !policy.item_results?
  end

  test "item_results?() authorizes everyone" do
    user    = users(:southwest)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = CollectionPolicy.new(context, @collection)
    assert policy.item_results?
  end

  # new?()

  test "new?() returns false with a nil user" do
    context = RequestContext.new(user:        nil,
                                 institution: @collection.institution)
    policy = CollectionPolicy.new(context, @collection)
    assert !policy.new?
  end

  test "new?() does not authorize an incorrect scope" do
    context = RequestContext.new(user:        users(:southwest_admin),
                                 institution: institutions(:northeast))
    policy  = CollectionPolicy.new(context, @collection)
    assert !policy.new?
  end

  test "new?() is restrictive by default" do
    user    = users(:southwest)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = CollectionPolicy.new(context, @collection)
    assert !policy.new?
  end

  test "new?() authorizes sysadmins" do
    user    = users(:southwest_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = CollectionPolicy.new(context, @collection)
    assert policy.new?
  end

  test "new?() works with class objects" do
    user    = users(:southwest)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = CollectionPolicy.new(context, Collection)
    assert !policy.new?
  end

  test "new?() respects role limits" do
    # sysadmin user limited to an insufficient role
    user    = users(:southwest_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::COLLECTION_SUBMITTER)
    policy  = CollectionPolicy.new(context, @collection)
    assert !policy.new?
  end

  # show?()

  test "show?() returns true with a nil user" do
    context = RequestContext.new(user:        nil,
                                 institution: @collection.institution)
    policy = CollectionPolicy.new(context, @collection)
    assert policy.show?
  end

  test "show?() does not authorize an incorrect scope" do
    context = RequestContext.new(user:        users(:southwest_admin),
                                 institution: institutions(:northeast))
    policy  = CollectionPolicy.new(context, @collection)
    assert !policy.show?
  end

  test "show?() authorizes everyone" do
    user    = users(:southwest)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = CollectionPolicy.new(context, @collection)
    assert policy.show?
  end

  # show_about?()

  test "show_about?() returns true with a nil user" do
    context = RequestContext.new(user:        nil,
                                 institution: @collection.institution)
    policy = CollectionPolicy.new(context, @collection)
    assert policy.show_about?
  end

  test "show_about?() does not authorize an incorrect scope" do
    context = RequestContext.new(user:        users(:southwest_admin),
                                 institution: institutions(:northeast))
    policy  = CollectionPolicy.new(context, @collection)
    assert !policy.show_about?
  end

  test "show_about?() authorizes everyone" do
    user    = users(:southwest)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = CollectionPolicy.new(context, @collection)
    assert policy.show_about?
  end

  # show_access?()

  test "show_access?() returns false with a nil user" do
    context = RequestContext.new(user:        nil,
                                 institution: @collection.institution)
    policy = CollectionPolicy.new(context, @collection)
    assert !policy.show_access?
  end

  test "show_access?() does not authorize an incorrect scope" do
    context = RequestContext.new(user:        users(:southwest_admin),
                                 institution: institutions(:northeast))
    policy  = CollectionPolicy.new(context, @collection)
    assert !policy.show_access?
  end

  test "show_access?() is restrictive by default" do
    user    = users(:southwest)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = CollectionPolicy.new(context, @collection)
    assert !policy.show_access?
  end

  test "show_access?() authorizes sysadmins" do
    user    = users(:southwest_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = CollectionPolicy.new(context, @collection)
    assert policy.show_access?
  end

  test "show_access?() respects role limits" do
    # sysadmin user limited to an insufficient role
    user    = users(:southwest_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::COLLECTION_SUBMITTER)
    policy  = CollectionPolicy.new(context, @collection)
    assert !policy.show_access?
  end

  # show_extended_about?()

  test "show_extended_about?() returns false with a nil user" do
    context = RequestContext.new(user:        nil,
                                 institution: @collection.institution)
    policy = CollectionPolicy.new(context, @collection)
    assert !policy.show_extended_about?
  end

  test "show_extended_about?() does not authorize an incorrect scope" do
    context = RequestContext.new(user:        users(:southwest_admin),
                                 institution: institutions(:northeast))
    policy  = CollectionPolicy.new(context, @collection)
    assert !policy.show_extended_about?
  end

  test "show_extended_about?() is restrictive by default" do
    user    = users(:southwest)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = CollectionPolicy.new(context, @collection)
    assert !policy.show_extended_about?
  end

  test "show_extended_about?() authorizes sysadmins" do
    user    = users(:southwest_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = CollectionPolicy.new(context, @collection)
    assert policy.show_extended_about?
  end

  test "show_extended_about?() authorizes collection administrators" do
    user = users(:southwest)
    user.administering_collections << @collection
    user.save!
    user    = users(:southwest)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = CollectionPolicy.new(context, @collection)
    assert policy.show_extended_about?
  end

  test "show_extended_about?() respects role limits" do
    # sysadmin user limited to an insufficient role
    user    = users(:southwest_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::LOGGED_IN)
    policy  = CollectionPolicy.new(context, @collection)
    assert !policy.show_extended_about?
  end

  # show_items?()

  test "show_items?() returns true with a nil user" do
    context = RequestContext.new(user:        nil,
                                 institution: @collection.institution)
    policy = CollectionPolicy.new(context, @collection)
    assert policy.show_items?
  end

  test "show_items?() does not authorize an incorrect scope" do
    context = RequestContext.new(user:        users(:southwest_admin),
                                 institution: institutions(:northeast))
    policy  = CollectionPolicy.new(context, @collection)
    assert !policy.show_items?
  end

  test "show_items?() authorizes everyone" do
    user    = users(:southwest)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = CollectionPolicy.new(context, @collection)
    assert policy.show_items?
  end

  # show_review_submissions?()

  test "show_review_submissions?() returns false with a nil user" do
    context = RequestContext.new(user:        nil,
                                 institution: @collection.institution)
    policy = CollectionPolicy.new(context, @collection)
    assert !policy.show_review_submissions?
  end

  test "show_review_submissions?() does not authorize an incorrect scope" do
    context = RequestContext.new(user:        users(:southwest_admin),
                                 institution: institutions(:northeast))
    policy  = CollectionPolicy.new(context, @collection)
    assert !policy.show_review_submissions?
  end

  test "show_review_submissions?() is restrictive by default" do
    user    = users(:southwest)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = CollectionPolicy.new(context, @collection)
    assert !policy.show_review_submissions?
  end

  test "show_review_submissions?() authorizes sysadmins" do
    user    = users(:southwest_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = CollectionPolicy.new(context, @collection)
    assert policy.show_review_submissions?
  end

  test "show_review_submissions?() authorizes collection administrators" do
    user = users(:southwest)
    user.administering_collections << @collection
    user.save!
    user    = users(:southwest)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = CollectionPolicy.new(context, @collection)
    assert policy.show_review_submissions?
  end

  test "show_review_submissions?() respects role limits" do
    # sysadmin user limited to an insufficient role
    user    = users(:southwest_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::LOGGED_IN)
    policy  = CollectionPolicy.new(context, @collection)
    assert !policy.show_review_submissions?
  end

  # show_statistics?()

  test "show_statistics?() returns true with a nil user" do
    context = RequestContext.new(user:        nil,
                                 institution: @collection.institution)
    policy = CollectionPolicy.new(context, @collection)
    assert policy.show_statistics?
  end

  test "show_statistics?() does not authorize an incorrect scope" do
    context = RequestContext.new(user:        users(:southwest_admin),
                                 institution: institutions(:northeast))
    policy  = CollectionPolicy.new(context, @collection)
    assert !policy.show_statistics?
  end

  test "show_statistics?() authorizes everyone" do
    user    = users(:southwest)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = CollectionPolicy.new(context, @collection)
    assert policy.show_statistics?
  end

  # show_submissions_in_progress?()

  test "show_submissions_in_progress?() returns false with a nil user" do
    context = RequestContext.new(user:        nil,
                                 institution: @collection.institution)
    policy  = CollectionPolicy.new(context, @collection)
    assert !policy.show_submissions_in_progress?
  end

  test "show_submissions_in_progress?() does not authorize an incorrect scope" do
    context = RequestContext.new(user:        users(:southwest_admin),
                                 institution: institutions(:northeast))
    policy  = CollectionPolicy.new(context, @collection)
    assert !policy.show_submissions_in_progress?
  end

  test "show_submissions_in_progress?() is restrictive by default" do
    user    = users(:southwest)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = CollectionPolicy.new(context, @collection)
    assert !policy.show_submissions_in_progress?
  end

  test "show_submissions_in_progress?() authorizes sysadmins" do
    user    = users(:southwest_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = CollectionPolicy.new(context, @collection)
    assert policy.show_submissions_in_progress?
  end

  test "show_submissions_in_progress?() authorizes collection administrators" do
    user    = users(:southwest)
    user.administering_collections << @collection
    user.save!
    user    = users(:southwest)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = CollectionPolicy.new(context, @collection)
    assert policy.show_submissions_in_progress?
  end

  test "show_submissions_in_progress?() respects role limits" do
    # sysadmin user limited to an insufficient role
    user    = users(:southwest_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::LOGGED_IN)
    policy  = CollectionPolicy.new(context, @collection)
    assert !policy.show_submissions_in_progress?
  end

  # statistics_by_range?()

  test "statistics_by_range?() returns true with a nil user" do
    context = RequestContext.new(user:        nil,
                                 institution: @collection.institution)
    policy = CollectionPolicy.new(context, @collection)
    assert policy.statistics_by_range?
  end

  test "statistics_by_range?() does not authorize an incorrect scope" do
    context = RequestContext.new(user:        users(:southwest_admin),
                                 institution: institutions(:northeast))
    policy  = CollectionPolicy.new(context, @collection)
    assert !policy.statistics_by_range?
  end

  test "statistics_by_range?() authorizes everyone" do
    user    = users(:southwest)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = CollectionPolicy.new(context, @collection)
    assert policy.statistics_by_range?
  end

  # submit_item?()

  test "submit_item?() returns false with a nil user" do
    context = RequestContext.new(user:        nil,
                                 institution: @collection.institution)
    policy = CollectionPolicy.new(context, @collection)
    assert !policy.submit_item?
  end

  test "submit_item?() does not authorize an incorrect scope" do
    context = RequestContext.new(user:        users(:southwest_admin),
                                 institution: institutions(:northeast))
    policy  = CollectionPolicy.new(context, @collection)
    assert !policy.submit_item?
  end

  test "submit_item?() is restrictive by default" do
    user    = users(:southwest)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = CollectionPolicy.new(context, @collection)
    assert !policy.submit_item?
  end

  test "submit_item?() authorizes sysadmins" do
    user    = users(:southwest_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = CollectionPolicy.new(context, @collection)
    assert policy.submit_item?
  end

  test "submit_item?() authorizes unit admins" do
    user    = users(:southwest)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)

    unit = @collection.units.first
    unit.administrators.build(user: user)
    unit.save!

    policy = CollectionPolicy.new(context, @collection)
    assert policy.submit_item?
  end

  test "submit_item?() authorizes collection administrators" do
    user    = users(:southwest)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)

    @collection.administering_users << user
    @collection.save!

    policy = CollectionPolicy.new(context, @collection)
    assert policy.submit_item?
  end

  test "submit_item?() authorizes collection submitters" do
    user    = users(:southwest)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)

    @collection.submitting_users << user
    @collection.save!

    policy = CollectionPolicy.new(context, @collection)
    assert policy.submit_item?
  end

  test "submit_item?() respects role limits" do
    # sysadmin user limited to an insufficient role
    user    = users(:southwest_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::LOGGED_IN)
    policy  = CollectionPolicy.new(context, @collection)
    assert !policy.submit_item?
  end

  # undelete?()

  test "undelete?() returns false with a nil user" do
    context = RequestContext.new(user:        nil,
                                 institution: @collection.institution)
    policy = CollectionPolicy.new(context, @collection)
    assert !policy.undelete?
  end

  test "undelete?() does not authorize an incorrect scope" do
    context = RequestContext.new(user:        users(:southwest_admin),
                                 institution: institutions(:northeast))
    policy  = CollectionPolicy.new(context, @collection)
    assert !policy.undelete?
  end

  test "undelete?() is restrictive by default" do
    user    = users(:southwest)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = CollectionPolicy.new(context, @collection)
    assert !policy.undelete?
  end

  test "undelete?() authorizes sysadmins" do
    user    = users(:southwest_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = CollectionPolicy.new(context, @collection)
    assert policy.undelete?
  end

  test "undelete?() authorizes institution admins" do
    user    = users(:southwest_admin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = CollectionPolicy.new(context, @collection)
    assert policy.undelete?
  end

  test "undelete?() respects role limits" do
    # sysadmin user limited to an insufficient role
    user    = users(:southwest_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::COLLECTION_SUBMITTER)
    policy  = CollectionPolicy.new(context, @collection)
    assert !policy.undelete?
  end

  # update?()

  test "update?() returns false with a nil user" do
    context = RequestContext.new(user:        nil,
                                 institution: @collection.institution)
    policy = CollectionPolicy.new(context, @collection)
    assert !policy.update?
  end

  test "update?() does not authorize an incorrect scope" do
    context = RequestContext.new(user:        users(:southwest_admin),
                                 institution: institutions(:northeast))
    policy  = CollectionPolicy.new(context, @collection)
    assert !policy.update?
  end

  test "update?() is restrictive by default" do
    user    = users(:southwest)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = CollectionPolicy.new(context, @collection)
    assert !policy.update?
  end

  test "update?() authorizes sysadmins" do
    user    = users(:southwest_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = CollectionPolicy.new(context, @collection)
    assert policy.update?
  end

  test "update?() authorizes unit admins" do
    user    = users(:southwest)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)

    unit = @collection.units.first
    unit.administrators.build(user: user)
    unit.save!

    policy = CollectionPolicy.new(context, @collection)
    assert policy.update?
  end

  test "update?() authorizes collection administrators" do
    user    = users(:southwest)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)

    @collection.administering_users << user
    @collection.save!

    policy = CollectionPolicy.new(context, @collection)
    assert policy.update?
  end

  test "update?() respects role limits" do
    # sysadmin user limited to an insufficient role
    user    = users(:southwest_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::COLLECTION_SUBMITTER)
    policy  = CollectionPolicy.new(context, @collection)
    assert !policy.update?
  end

end
