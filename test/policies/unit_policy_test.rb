require 'test_helper'

class UnitPolicyTest < ActiveSupport::TestCase

  setup do
    @unit = units(:southwest_unit1)
  end

  # change_parent?()

  test "change_parent?() returns false with a nil user" do
    context = RequestContext.new(user:        nil,
                                 institution: @unit.institution)
    unit2   = units(:southwest_unit2)
    policy  = UnitPolicy.new(context, @unit)
    assert !policy.change_parent?(unit2.id)
  end

  test "change_parent?() is restrictive by default" do
    user    = users(:southwest)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    unit2   = units(:southwest_unit2)
    policy  = UnitPolicy.new(context, @unit)
    assert !policy.change_parent?(unit2.id)
  end

  test "change_parent?() does not authorize users who are admins of the source
  parent but not the destination parent" do
    user    = users(:southwest)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    @unit.primary_administrator = user
    new_parent = units(:southwest_unit2)
    new_parent.primary_administrator = nil

    policy  = UnitPolicy.new(context, @unit)
    assert !policy.change_parent?(new_parent.id)
  end

  test "change_parent?() does not authorize users who are admins of the
  destination parent but not the source parent" do
    user    = users(:southwest)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    @unit.primary_administrator = nil
    new_parent = units(:southwest_unit2)
    new_parent.primary_administrator = user

    policy  = UnitPolicy.new(context, @unit)
    assert !policy.change_parent?(new_parent.id)
  end

  test "change_parent?() authorizes users who are admins of both the source and
  destination parents" do
    user    = users(:southwest)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    @unit.primary_administrator = user
    new_parent = units(:southwest_unit2)
    new_parent.primary_administrator = user

    policy  = UnitPolicy.new(context, @unit)
    assert policy.change_parent?(new_parent.id)
  end

  test "change_parent?() authorizes sysadmins" do
    user    = users(:southwest_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    unit2   = units(:southwest_unit2)
    policy  = UnitPolicy.new(context, @unit)
    assert policy.change_parent?(unit2.id)
  end

  test "change_parent?() respects role limits" do
    # sysadmin user limited to an insufficient role
    user    = users(:southwest_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::LOGGED_IN)
    unit2   = units(:southwest_unit2)
    policy  = UnitPolicy.new(context, @unit)
    assert !policy.change_parent?(unit2.id)
  end

  # children?()

  test "children?() returns true with a nil user" do
    context = RequestContext.new(user:        nil,
                                 institution: @unit.institution)
    policy = UnitPolicy.new(context, @unit)
    assert policy.children?
  end

  test "children?() authorizes everyone" do
    user    = users(:southwest)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = UnitPolicy.new(context, @unit)
    assert policy.children?
  end

  # collections_tree_fragment?()

  test "collections_tree_fragment?() returns true with a nil user" do
    context = RequestContext.new(user:        nil,
                                 institution: @unit.institution)
    policy = UnitPolicy.new(context, @unit)
    assert policy.collections_tree_fragment?
  end

  test "collections_tree_fragment?() authorizes everyone" do
    user    = users(:southwest)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = UnitPolicy.new(context, @unit)
    assert policy.collections_tree_fragment?
  end

  # create?()

  test "create?() returns false with a nil user" do
    context = RequestContext.new(user:        nil,
                                 institution: @unit.institution)
    policy = UnitPolicy.new(context, @unit)
    assert !policy.create?
  end

  test "create?() is restrictive by default" do
    user    = users(:southwest)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = UnitPolicy.new(context, @unit)
    assert !policy.create?
  end

  test "create?() authorizes sysadmins" do
    user    = users(:southwest_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = UnitPolicy.new(context, @unit)
    assert policy.create?
  end

  test "create?() authorizes institution admins" do
    user    = users(:southwest_admin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = UnitPolicy.new(context, @unit)
    assert policy.create?
  end

  test "create?() authorizes admins of the parent unit" do
    user    = users(:southwest)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    @unit.administering_users << user
    child_unit = Unit.create!(institution: @unit.institution,
                              parent:      @unit,
                              title:       "Child Unit")
    policy     = UnitPolicy.new(context, child_unit)
    assert policy.create?
  end

  test "create?() respects role limits" do
    # sysadmin user limited to an insufficient role
    user    = users(:southwest_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::LOGGED_IN)
    policy  = UnitPolicy.new(context, @unit)
    assert !policy.create?
  end

  # delete?()

  test "delete?() returns false with a nil user" do
    context = RequestContext.new(user:        nil,
                                 institution: @unit.institution)
    policy = UnitPolicy.new(context, @unit)
    assert !policy.delete?
  end

  test "delete?() is restrictive by default" do
    user    = users(:southwest)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = UnitPolicy.new(context, @unit)
    assert !policy.delete?
  end

  test "delete?() authorizes sysadmins" do
    user    = users(:southwest_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = UnitPolicy.new(context, @unit)
    assert policy.delete?
  end

  test "delete?() authorizes institution admins" do
    user    = users(:southwest_admin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = UnitPolicy.new(context, @unit)
    assert policy.delete?
  end

  test "delete?() respects role limits" do
    # sysadmin user limited to an insufficient role
    user    = users(:southwest_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::LOGGED_IN)
    policy  = UnitPolicy.new(context, @unit)
    assert !policy.delete?
  end

  # edit_administering_groups?()

  test "edit_administering_groups?() returns false with a nil user" do
    context = RequestContext.new(user:        nil,
                                 institution: @unit.institution)
    policy = UnitPolicy.new(context, @unit)
    assert !policy.edit_administering_groups?
  end

  test "edit_administering_groups?() is restrictive by default" do
    user    = users(:southwest)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = UnitPolicy.new(context, @unit)
    assert !policy.edit_administering_groups?
  end

  test "edit_administering_groups?() authorizes sysadmins" do
    user    = users(:southwest_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = UnitPolicy.new(context, @unit)
    assert policy.edit_administering_groups?
  end

  test "edit_administering_groups?() respects role limits" do
    # sysadmin user limited to an insufficient role
    user    = users(:southwest_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::LOGGED_IN)
    policy  = UnitPolicy.new(context, @unit)
    assert !policy.edit_administering_groups?
  end

  # edit_administering_users?()

  test "edit_administering_users?() returns false with a nil user" do
    context = RequestContext.new(user:        nil,
                                 institution: @unit.institution)
    policy = UnitPolicy.new(context, @unit)
    assert !policy.edit_administering_users?
  end

  test "edit_administering_users?() is restrictive by default" do
    user    = users(:southwest)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = UnitPolicy.new(context, @unit)
    assert !policy.edit_administering_users?
  end

  test "edit_administering_users?() authorizes sysadmins" do
    user    = users(:southwest_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = UnitPolicy.new(context, @unit)
    assert policy.edit_administering_users?
  end

  test "edit_administering_users?() respects role limits" do
    # sysadmin user limited to an insufficient role
    user    = users(:southwest_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::LOGGED_IN)
    policy  = UnitPolicy.new(context, @unit)
    assert !policy.edit_administering_users?
  end

  # edit_membership?()

  test "edit_membership?() returns false with a nil user" do
    context = RequestContext.new(user:        nil,
                                 institution: @unit.institution)
    policy = UnitPolicy.new(context, @unit)
    assert !policy.edit_membership?
  end

  test "edit_membership?() is restrictive by default" do
    user    = users(:southwest)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = UnitPolicy.new(context, @unit)
    assert !policy.edit_membership?
  end

  test "edit_membership?() authorizes sysadmins" do
    user    = users(:southwest_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = UnitPolicy.new(context, @unit)
    assert policy.edit_membership?
  end

  test "edit_membership?() respects role limits" do
    # sysadmin user limited to an insufficient role
    user    = users(:southwest_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::LOGGED_IN)
    policy  = UnitPolicy.new(context, @unit)
    assert !policy.edit_membership?
  end

  # edit_properties?()

  test "edit_properties?() returns false with a nil user" do
    context = RequestContext.new(user:        nil,
                                 institution: @unit.institution)
    policy = UnitPolicy.new(context, @unit)
    assert !policy.edit_properties?
  end

  test "edit_properties?() is restrictive by default" do
    user    = users(:southwest)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = UnitPolicy.new(context, @unit)
    assert !policy.edit_properties?
  end

  test "edit_properties?() authorizes sysadmins" do
    user    = users(:southwest_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = UnitPolicy.new(context, @unit)
    assert policy.edit_properties?
  end

  test "edit_properties?() respects role limits" do
    # sysadmin user limited to an insufficient role
    user    = users(:southwest_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::LOGGED_IN)
    policy  = UnitPolicy.new(context, @unit)
    assert !policy.edit_properties?
  end

  # export_items?()

  test "export_items?() returns false with a nil user" do
    context = RequestContext.new(user:        nil,
                                 institution: @unit.institution)
    policy = UnitPolicy.new(context, @unit)
    assert !policy.export_items?
  end

  test "export_items?() is restrictive by default" do
    user    = users(:southwest)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = UnitPolicy.new(context, @unit)
    assert !policy.export_items?
  end

  test "export_items?() authorizes sysadmins" do
    user    = users(:southwest_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy = UnitPolicy.new(context, @unit)
    assert policy.export_items?
  end

  test "export_items?() respects role limits" do
    # sysadmin user limited to an insufficient role
    user    = users(:southwest_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::LOGGED_IN)
    policy  = UnitPolicy.new(context, @unit)
    assert !policy.export_items?
  end

  # index?()

  test "index?() returns true with a nil user" do
    context = RequestContext.new(user:        nil,
                                 institution: @unit.institution)
    policy = UnitPolicy.new(context, Unit)
    assert policy.index?
  end

  test "index?() authorizes everyone" do
    user    = users(:southwest)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = UnitPolicy.new(context, Unit)
    assert policy.index?
  end

  # item_download_counts?()

  test "item_download_counts?() returns true with a nil user" do
    context = RequestContext.new(user:        nil,
                                 institution: @unit.institution)
    policy = UnitPolicy.new(context, @unit)
    assert policy.item_download_counts?
  end

  test "item_download_counts?() authorizes everyone" do
    user    = users(:southwest)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = UnitPolicy.new(context, @unit)
    assert policy.item_download_counts?
  end

  # item_results?()

  test "item_results?() returns true with a nil user" do
    context = RequestContext.new(user:        nil,
                                 institution: @unit.institution)
    policy = UnitPolicy.new(context, @unit)
    assert policy.item_results?
  end

  test "item_results?() authorizes everyone" do
    user    = users(:southwest)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = UnitPolicy.new(context, @unit)
    assert policy.item_results?
  end

  # new?()

  test "new?() returns false with a nil user" do
    context = RequestContext.new(user:        nil,
                                 institution: @unit.institution)
    policy = UnitPolicy.new(context, @unit)
    assert !policy.new?
  end

  test "new?() is restrictive by default" do
    user    = users(:southwest)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = UnitPolicy.new(context, @unit)
    assert !policy.new?
  end

  test "new?() returns true when the target object is a Unit" do
    user    = users(:southwest_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = UnitPolicy.new(context, Unit)
    assert policy.new?
  end

  test "new?() authorizes sysadmins" do
    user    = users(:southwest_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy = UnitPolicy.new(context, @unit)
    assert policy.new?
  end

  test "new?() respects role limits" do
    # sysadmin user limited to an insufficient role
    user    = users(:southwest_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::LOGGED_IN)
    policy  = UnitPolicy.new(context, @unit)
    assert !policy.new?
  end

  # new_collection?()

  test "new_collection?() returns false with a nil user" do
    context = RequestContext.new(user:        nil,
                                 institution: @unit.institution)
    policy = UnitPolicy.new(context, @unit)
    assert !policy.new_collection?
  end

  test "new_collection?() is restrictive by default" do
    user    = users(:southwest)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = UnitPolicy.new(context, @unit)
    assert !policy.new_collection?
  end

  test "new_collection?() authorizes sysadmins" do
    user    = users(:southwest_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy = UnitPolicy.new(context, @unit)
    assert policy.new_collection?
  end

  test "new_collection?() authorizes unit admins" do
    user    = users(:southwest)
    @unit.administering_users << user
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy = UnitPolicy.new(context, @unit)
    assert policy.new_collection?
  end

  test "new_collection?() respects role limits" do
    # sysadmin user limited to an insufficient role
    user    = users(:southwest_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::LOGGED_IN)
    policy  = UnitPolicy.new(context, @unit)
    assert !policy.new_collection?
  end

  # show?()

  test "show?() returns true with a nil user" do
    context = RequestContext.new(user:        nil,
                                 institution: @unit.institution)
    policy = UnitPolicy.new(context, @unit)
    assert policy.show?
  end

  test "show?() authorizes everyone" do
    user    = users(:southwest)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = UnitPolicy.new(context, @unit)
    assert policy.show?
  end

  # show_about?()

  test "show_about?() returns true with a nil user" do
    context = RequestContext.new(user:        nil,
                                 institution: @unit.institution)
    policy = UnitPolicy.new(context, @unit)
    assert policy.show_about?
  end

  test "show_about?() authorizes everyone" do
    user    = users(:southwest)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = UnitPolicy.new(context, @unit)
    assert policy.show_about?
  end

  # show_access?()

  test "show_access?() returns false with a nil user" do
    context = RequestContext.new(user:        nil,
                                 institution: @unit.institution)
    policy = UnitPolicy.new(context, @unit)
    assert !policy.show_access?
  end

  test "show_access?() is restrictive by default" do
    user    = users(:southwest)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = UnitPolicy.new(context, @unit)
    assert !policy.show_access?
  end

  test "show_access?() authorizes sysadmins" do
    user    = users(:southwest_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy = UnitPolicy.new(context, @unit)
    assert policy.show_access?
  end

  test "show_access?() respects role limits" do
    # sysadmin user limited to an insufficient role
    user    = users(:southwest_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::LOGGED_IN)
    policy  = UnitPolicy.new(context, @unit)
    assert !policy.show_access?
  end

  # show_collections?()

  test "show_collections?() returns true with a nil user" do
    context = RequestContext.new(user:        nil,
                                 institution: @unit.institution)
    policy = UnitPolicy.new(context, @unit)
    assert policy.show_collections?
  end

  test "show_collections?() authorizes everyone" do
    user    = users(:southwest)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = UnitPolicy.new(context, @unit)
    assert policy.show_collections?
  end

  # show_extended_about?()

  test "show_extended_about?() returns false with a nil user" do
    context = RequestContext.new(user:        nil,
                                 institution: @unit.institution)
    policy = UnitPolicy.new(context, @unit)
    assert !policy.show_extended_about?
  end

  test "show_extended_about?() is restrictive by default" do
    user    = users(:southwest)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = UnitPolicy.new(context, @unit)
    assert !policy.show_extended_about?
  end

  test "show_extended_about?() authorizes sysadmins" do
    user    = users(:southwest_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy = UnitPolicy.new(context, @unit)
    assert policy.show_extended_about?
  end

  test "show_extended_about?() respects role limits" do
    # sysadmin user limited to an insufficient role
    user    = users(:southwest_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::LOGGED_IN)
    policy  = UnitPolicy.new(context, @unit)
    assert !policy.show_extended_about?
  end

  # show_items?()

  test "show_items?() returns true with a nil user" do
    context = RequestContext.new(user:        nil,
                                 institution: @unit.institution)
    policy = UnitPolicy.new(context, @unit)
    assert policy.show_items?
  end

  test "show_items?() authorizes everyone" do
    user    = users(:southwest)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = UnitPolicy.new(context, @unit)
    assert policy.show_items?
  end

  # show_statistics?()

  test "show_statistics?() returns true with a nil user" do
    context = RequestContext.new(user:        nil,
                                 institution: @unit.institution)
    policy = UnitPolicy.new(context, @unit)
    assert policy.show_statistics?
  end

  test "show_statistics?() authorizes everyone" do
    user    = users(:southwest)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = UnitPolicy.new(context, @unit)
    assert policy.show_statistics?
  end

  # show_unit_membership?()

  test "show_unit_membership?() returns true with a nil user" do
    context = RequestContext.new(user:        nil,
                                 institution: @unit.institution)
    policy = UnitPolicy.new(context, @unit)
    assert policy.show_unit_membership?
  end

  test "show_unit_membership?() authorizes everyone" do
    user    = users(:southwest)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = UnitPolicy.new(context, @unit)
    assert policy.show_unit_membership?
  end

  # statistics_by_range?()

  test "statistics_by_range?() returns true with a nil user" do
    context = RequestContext.new(user:        nil,
                                 institution: @unit.institution)
    policy = UnitPolicy.new(context, @unit)
    assert policy.statistics_by_range?
  end

  test "statistics_by_range?() authorizes everyone" do
    user    = users(:southwest)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = UnitPolicy.new(context, @unit)
    assert policy.statistics_by_range?
  end

  # undelete?()

  test "undelete?() returns false with a nil user" do
    context = RequestContext.new(user:        nil,
                                 institution: @unit.institution)
    policy = UnitPolicy.new(context, @unit)
    assert !policy.undelete?
  end

  test "undelete?() is restrictive by default" do
    user    = users(:southwest)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = UnitPolicy.new(context, @unit)
    assert !policy.undelete?
  end

  test "undelete?() authorizes sysadmins" do
    user    = users(:southwest_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = UnitPolicy.new(context, @unit)
    assert policy.undelete?
  end

  test "undelete?() authorizes institution admins" do
    user    = users(:southwest_admin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = UnitPolicy.new(context, @unit)
    assert policy.undelete?
  end

  test "undelete?() respects role limits" do
    # sysadmin user limited to an insufficient role
    user    = users(:southwest_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::LOGGED_IN)
    policy  = UnitPolicy.new(context, @unit)
    assert !policy.undelete?
  end

  # update?()

  test "update?() returns false with a nil user" do
    context = RequestContext.new(user:        nil,
                                 institution: @unit.institution)
    policy = UnitPolicy.new(context, @unit)
    assert !policy.update?
  end

  test "update?() is restrictive by default" do
    user    = users(:southwest)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = UnitPolicy.new(context, @unit)
    assert !policy.update?
  end

  test "update?() authorizes sysadmins" do
    user    = users(:southwest_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy = UnitPolicy.new(context, @unit)
    assert policy.update?
  end

  test "update?() respects role limits" do
    # sysadmin user limited to an insufficient role
    user    = users(:southwest_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::LOGGED_IN)
    policy  = UnitPolicy.new(context, @unit)
    assert !policy.update?
  end

end
