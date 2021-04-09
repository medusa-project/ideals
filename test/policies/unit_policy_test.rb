require 'test_helper'

class UnitPolicyTest < ActiveSupport::TestCase

  setup do
    @unit = units(:unit1)
  end

  # change_parent?()

  test "change_parent?() returns false with a nil user" do
    unit2 = units(:unit2)
    policy = UnitPolicy.new(nil, @unit)
    assert !policy.change_parent?(unit2.id)
  end

  test "change_parent?() is restrictive by default" do
    user    = users(:norights)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::NO_LIMIT)
    unit2   = units(:unit2)
    policy  = UnitPolicy.new(context, @unit)
    assert !policy.change_parent?(unit2.id)
  end

  test "change_parent?() authorizes sysadmins" do
    user    = users(:local_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::NO_LIMIT)
    unit2   = units(:unit2)
    policy  = UnitPolicy.new(context, @unit)
    assert policy.change_parent?(unit2.id)
  end

  test "change_parent?() respects role limits" do
    # sysadmin user limited to an insufficient role
    user    = users(:local_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::LOGGED_IN)
    unit2   = units(:unit2)
    policy  = UnitPolicy.new(context, @unit)
    assert !policy.change_parent?(unit2.id)
  end

  # children?()

  test "children?() returns true with a nil user" do
    policy = UnitPolicy.new(nil, @unit)
    assert policy.children?
  end

  test "children?() authorizes everyone" do
    user    = users(:norights)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::NO_LIMIT)
    policy  = UnitPolicy.new(context, @unit)
    assert policy.children?
  end

  # collections_tree_fragment?()

  test "collections_tree_fragment?() returns true with a nil user" do
    policy = UnitPolicy.new(nil, @unit)
    assert policy.collections_tree_fragment?
  end

  test "collections_tree_fragment?() authorizes everyone" do
    user    = users(:norights)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::NO_LIMIT)
    policy  = UnitPolicy.new(context, @unit)
    assert policy.collections_tree_fragment?
  end

  # create?()

  test "create?() returns false with a nil user" do
    policy = UnitPolicy.new(nil, @unit)
    assert !policy.create?
  end

  test "create?() is restrictive by default" do
    user    = users(:norights)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::NO_LIMIT)
    policy  = UnitPolicy.new(context, @unit)
    assert !policy.create?
  end

  test "create?() authorizes sysadmins" do
    user    = users(:local_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::NO_LIMIT)
    policy  = UnitPolicy.new(context, @unit)
    assert policy.create?
  end

  test "create?() authorizes institution admins" do
    user    = users(:somewhere_admin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::NO_LIMIT)
    policy  = UnitPolicy.new(context, @unit)
    assert policy.create?
  end

  test "create?() respects role limits" do
    # sysadmin user limited to an insufficient role
    user    = users(:local_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::LOGGED_IN)
    policy  = UnitPolicy.new(context, @unit)
    assert !policy.create?
  end

  # destroy?()

  test "destroy?() returns false with a nil user" do
    policy = UnitPolicy.new(nil, @unit)
    assert !policy.destroy?
  end

  test "destroy?() is restrictive by default" do
    user    = users(:norights)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::NO_LIMIT)
    policy  = UnitPolicy.new(context, @unit)
    assert !policy.destroy?
  end

  test "destroy?() authorizes sysadmins" do
    user    = users(:local_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::NO_LIMIT)
    policy  = UnitPolicy.new(context, @unit)
    assert policy.destroy?
  end

  test "destroy?() respects role limits" do
    # sysadmin user limited to an insufficient role
    user    = users(:local_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::LOGGED_IN)
    policy  = UnitPolicy.new(context, @unit)
    assert !policy.destroy?
  end

  # edit_access?()

  test "edit_access?() returns false with a nil user" do
    policy = UnitPolicy.new(nil, @unit)
    assert !policy.edit_access?
  end

  test "edit_access?() is restrictive by default" do
    user    = users(:norights)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::NO_LIMIT)
    policy  = UnitPolicy.new(context, @unit)
    assert !policy.edit_access?
  end

  test "edit_access?() authorizes sysadmins" do
    user    = users(:local_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::NO_LIMIT)
    policy  = UnitPolicy.new(context, @unit)
    assert policy.edit_access?
  end

  test "edit_access?() respects role limits" do
    # sysadmin user limited to an insufficient role
    user    = users(:local_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::LOGGED_IN)
    policy  = UnitPolicy.new(context, @unit)
    assert !policy.edit_access?
  end

  # edit_membership?()

  test "edit_membership?() returns false with a nil user" do
    policy = UnitPolicy.new(nil, @unit)
    assert !policy.edit_membership?
  end

  test "edit_membership?() is restrictive by default" do
    user    = users(:norights)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::NO_LIMIT)
    policy  = UnitPolicy.new(context, @unit)
    assert !policy.edit_membership?
  end

  test "edit_membership?() authorizes sysadmins" do
    user    = users(:local_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::NO_LIMIT)
    policy  = UnitPolicy.new(context, @unit)
    assert policy.edit_membership?
  end

  test "edit_membership?() respects role limits" do
    # sysadmin user limited to an insufficient role
    user    = users(:local_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::LOGGED_IN)
    policy  = UnitPolicy.new(context, @unit)
    assert !policy.edit_membership?
  end

  # edit_properties?()

  test "edit_properties?() returns false with a nil user" do
    policy = UnitPolicy.new(nil, @unit)
    assert !policy.edit_properties?
  end

  test "edit_properties?() is restrictive by default" do
    user    = users(:norights)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::NO_LIMIT)
    policy  = UnitPolicy.new(context, @unit)
    assert !policy.edit_properties?
  end

  test "edit_properties?() authorizes sysadmins" do
    user    = users(:local_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::NO_LIMIT)
    policy  = UnitPolicy.new(context, @unit)
    assert policy.edit_properties?
  end

  test "edit_properties?() respects role limits" do
    # sysadmin user limited to an insufficient role
    user    = users(:local_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::LOGGED_IN)
    policy  = UnitPolicy.new(context, @unit)
    assert !policy.edit_properties?
  end

  # index?()

  test "index?() returns true with a nil user" do
    policy = UnitPolicy.new(nil, Unit)
    assert policy.index?
  end

  test "index?() authorizes everyone" do
    user    = users(:norights)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::NO_LIMIT)
    policy  = UnitPolicy.new(context, Unit)
    assert policy.index?
  end

  # item_download_counts?()

  test "item_download_counts?() returns true with a nil user" do
    policy = UnitPolicy.new(nil, @unit)
    assert policy.item_download_counts?
  end

  test "item_download_counts?() authorizes everyone" do
    user    = users(:norights)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::NO_LIMIT)
    policy  = UnitPolicy.new(context, @unit)
    assert policy.item_download_counts?
  end

  # new?()

  test "new?() returns false with a nil user" do
    policy = UnitPolicy.new(nil, @unit)
    assert !policy.new?
  end

  test "new?() is restrictive by default" do
    user    = users(:norights)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::NO_LIMIT)
    policy  = UnitPolicy.new(context, @unit)
    assert !policy.new?
  end

  test "new?() returns true when the target object is a Unit" do
    user    = users(:local_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::NO_LIMIT)
    policy  = UnitPolicy.new(context, Unit)
    assert policy.new?
  end

  test "new?() authorizes sysadmins" do
    user    = users(:local_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::NO_LIMIT)
    policy = UnitPolicy.new(context, @unit)
    assert policy.new?
  end

  test "new?() respects role limits" do
    # sysadmin user limited to an insufficient role
    user    = users(:local_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::LOGGED_IN)
    policy  = UnitPolicy.new(context, @unit)
    assert !policy.new?
  end

  # show?()

  test "show?() returns true with a nil user" do
    policy = UnitPolicy.new(nil, @unit)
    assert policy.show?
  end

  test "show?() authorizes everyone" do
    user    = users(:norights)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::NO_LIMIT)
    policy  = UnitPolicy.new(context, @unit)
    assert policy.show?
  end

  # show_access?()

  test "show_access?() returns false with a nil user" do
    policy = UnitPolicy.new(nil, @unit)
    assert !policy.show_access?
  end

  test "show_access?() is restrictive by default" do
    user    = users(:norights)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::NO_LIMIT)
    policy  = UnitPolicy.new(context, @unit)
    assert !policy.show_access?
  end

  test "show_access?() authorizes sysadmins" do
    user    = users(:local_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::NO_LIMIT)
    policy = UnitPolicy.new(context, @unit)
    assert policy.show_access?
  end

  test "show_access?() respects role limits" do
    # sysadmin user limited to an insufficient role
    user    = users(:local_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::LOGGED_IN)
    policy  = UnitPolicy.new(context, @unit)
    assert !policy.show_access?
  end

  # show_collections?()

  test "show_collections?() returns true with a nil user" do
    policy = UnitPolicy.new(nil, @unit)
    assert policy.show_collections?
  end

  test "show_collections?() authorizes everyone" do
    user    = users(:norights)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::NO_LIMIT)
    policy  = UnitPolicy.new(context, @unit)
    assert policy.show_collections?
  end

  # show_items?()

  test "show_items?() returns true with a nil user" do
    policy = UnitPolicy.new(nil, @unit)
    assert policy.show_items?
  end

  test "show_items?() authorizes everyone" do
    user    = users(:norights)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::NO_LIMIT)
    policy  = UnitPolicy.new(context, @unit)
    assert policy.show_items?
  end

  # show_properties?()

  test "show_properties?() returns true with a nil user" do
    policy = UnitPolicy.new(nil, @unit)
    assert policy.show_properties?
  end

  test "show_properties?() authorizes everyone" do
    user    = users(:norights)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::NO_LIMIT)
    policy  = UnitPolicy.new(context, @unit)
    assert policy.show_properties?
  end

  # show_statistics?()

  test "show_statistics?() returns true with a nil user" do
    policy = UnitPolicy.new(nil, @unit)
    assert policy.show_statistics?
  end

  test "show_statistics?() authorizes everyone" do
    user    = users(:norights)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::NO_LIMIT)
    policy  = UnitPolicy.new(context, @unit)
    assert policy.show_statistics?
  end

  # show_unit_membership?()

  test "show_unit_membership?() returns true with a nil user" do
    policy = UnitPolicy.new(nil, @unit)
    assert policy.show_unit_membership?
  end

  test "show_unit_membership?() authorizes everyone" do
    user    = users(:norights)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::NO_LIMIT)
    policy  = UnitPolicy.new(context, @unit)
    assert policy.show_unit_membership?
  end

  # statistics_by_range?()

  test "statistics_by_range?() returns true with a nil user" do
    policy = UnitPolicy.new(nil, @unit)
    assert policy.statistics_by_range?
  end

  test "statistics_by_range?() authorizes everyone" do
    user    = users(:norights)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::NO_LIMIT)
    policy  = UnitPolicy.new(context, @unit)
    assert policy.statistics_by_range?
  end

  # update?()

  test "update?() returns false with a nil user" do
    policy = UnitPolicy.new(nil, @unit)
    assert !policy.update?
  end

  test "update?() is restrictive by default" do
    user    = users(:norights)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::NO_LIMIT)
    policy  = UnitPolicy.new(context, @unit)
    assert !policy.update?
  end

  test "update?() authorizes sysadmins" do
    user    = users(:local_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::NO_LIMIT)
    policy = UnitPolicy.new(context, @unit)
    assert policy.update?
  end

  test "update?() respects role limits" do
    # sysadmin user limited to an insufficient role
    user    = users(:local_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::LOGGED_IN)
    policy  = UnitPolicy.new(context, @unit)
    assert !policy.update?
  end

end
