require 'test_helper'

class UserPolicyTest < ActiveSupport::TestCase

  setup do
    @object_user = users(:norights)
  end

  # edit_properties?()

  test "edit_properties?() returns false with a nil request context" do
    policy = UserPolicy.new(nil, @object_user)
    assert !policy.edit_properties?
  end

  test "edit_properties?() does not authorize non-sysadmins other than the one
  being edited" do
    user    = users(:uiuc)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = UserPolicy.new(context, @object_user)
    assert !policy.edit_properties?
  end

  test "edit_properties?() authorizes the same user as the one being edited" do
    user    = users(:norights)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = UserPolicy.new(context, context.user)
    assert policy.edit_properties?
  end

  test "edit_properties?() authorizes sysadmins" do
    user    = users(:local_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy = UserPolicy.new(context, @object_user)
    assert policy.edit_properties?
  end

  test "edit_properties?() respects role limits" do
    # sysadmin user limited to an insufficient role
    user    = users(:local_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::LOGGED_IN)
    policy  = UserPolicy.new(context, @object_user)
    assert !policy.edit_properties?
  end

  # index?()

  test "index?() returns false with a nil request context" do
    policy = UserPolicy.new(nil, User)
    assert !policy.index?
  end

  test "index?() does not authorize non-sysadmins" do
    user    = users(:norights)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = UserPolicy.new(context, User)
    assert !policy.index?
  end

  test "index?() authorizes sysadmins" do
    user    = users(:local_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy = UserPolicy.new(context, User)
    assert policy.index?
  end

  test "index?() respects role limits" do
    # sysadmin user limited to an insufficient role
    user    = users(:local_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::LOGGED_IN)
    policy  = UserPolicy.new(context, @object_user)
    assert !policy.index?
  end

  # invite?()

  test "invite?() returns false with a nil request context" do
    policy = UserPolicy.new(nil, @object_user)
    assert !policy.invite?
  end

  test "invite?() does not authorize non-sysadmins" do
    user    = users(:norights)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = UserPolicy.new(context, @object_user)
    assert !policy.invite?
  end

  test "invite?() authorizes sysadmins" do
    user    = users(:local_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = UserPolicy.new(context, @object_user)
    assert policy.invite?
  end

  test "invite?() respects role limits" do
    # sysadmin user limited to an insufficient role
    user    = users(:local_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::LOGGED_IN)
    policy  = UserPolicy.new(context, @object_user)
    assert !policy.invite?
  end

  # show?()

  test "show?() returns false with a nil request context" do
    policy = UserPolicy.new(nil, @object_user)
    assert !policy.show?
  end

  test "show?() does not authorize non-sysadmins" do
    user    = users(:uiuc)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = UserPolicy.new(context, @object_user)
    assert !policy.show?
  end

  test "show?() authorizes sysadmins" do
    user    = users(:local_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = UserPolicy.new(context, @object_user)
    assert policy.show?
  end

  test "show?() respects role limits" do
    # sysadmin user limited to an insufficient role
    user    = users(:local_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::LOGGED_IN)
    policy  = UserPolicy.new(context, @object_user)
    assert !policy.show?
  end

  # show_properties?()

  test "show_properties?() returns false with a nil request context" do
    policy = UserPolicy.new(nil, @object_user)
    assert !policy.show_properties?
  end

  test "show_properties?() does not authorize non-sysadmins" do
    user    = users(:uiuc)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = UserPolicy.new(context, @object_user)
    assert !policy.show_properties?
  end

  test "show_properties?() authorizes sysadmins" do
    user    = users(:local_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = UserPolicy.new(context, @object_user)
    assert policy.show_properties?
  end

  test "show_properties?() respects role limits" do
    # sysadmin user limited to an insufficient role
    user    = users(:local_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::LOGGED_IN)
    policy  = UserPolicy.new(context, @object_user)
    assert !policy.show_properties?
  end

  # show_submittable_collections?()

  test "show_submittable_collections?() returns false with a nil request context" do
    policy = UserPolicy.new(nil, @object_user)
    assert !policy.show_submittable_collections?
  end

  test "show_submittable_collections?() does not authorize non-sysadmins" do
    user    = users(:uiuc)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = UserPolicy.new(context, @object_user)
    assert !policy.show_submittable_collections?
  end

  test "show_submittable_collections?() authorizes sysadmins" do
    user    = users(:local_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = UserPolicy.new(context, @object_user)
    assert policy.show_submittable_collections?
  end

  test "show_submittable_collections?() respects role limits" do
    # sysadmin user limited to an insufficient role
    user    = users(:local_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::LOGGED_IN)
    policy  = UserPolicy.new(context, @object_user)
    assert !policy.show_submittable_collections?
  end

  # show_submitted_items?()

  test "show_submitted_items?() returns false with a nil request context" do
    policy = UserPolicy.new(nil, @object_user)
    assert !policy.show_submitted_items?
  end

  test "show_submitted_items?() does not authorize non-sysadmins" do
    user    = users(:uiuc)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = UserPolicy.new(context, @object_user)
    assert !policy.show_submitted_items?
  end

  test "show_submitted_items?() authorizes sysadmins" do
    user    = users(:local_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = UserPolicy.new(context, @object_user)
    assert policy.show_submitted_items?
  end

  test "show_submitted_items?() respects role limits" do
    # sysadmin user limited to an insufficient role
    user    = users(:local_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::LOGGED_IN)
    policy  = UserPolicy.new(context, @object_user)
    assert !policy.show_submitted_items?
  end

  # show_submissions_in_progress?()

  test "show_submissions_in_progress?() returns false with a nil request context" do
    policy = UserPolicy.new(nil, @object_user)
    assert !policy.show_submissions_in_progress?
  end

  test "show_submissions_in_progress?() does not authorize non-sysadmins" do
    user    = users(:uiuc)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = UserPolicy.new(context, @object_user)
    assert !policy.show_submissions_in_progress?
  end

  test "show_submissions_in_progress?() authorizes sysadmins" do
    user    = users(:local_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = UserPolicy.new(context, @object_user)
    assert policy.show_submissions_in_progress?
  end

  test "show_submissions_in_progress?() respects role limits" do
    # sysadmin user limited to an insufficient role
    user    = users(:local_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::LOGGED_IN)
    policy  = UserPolicy.new(context, @object_user)
    assert !policy.show_submissions_in_progress?
  end

  # submitted_item_results?()

  test "submitted_item_results?() returns false with a nil request context" do
    policy = UserPolicy.new(nil, @object_user)
    assert !policy.submitted_item_results?
  end

  test "submitted_item_results?() does not authorize non-sysadmins" do
    user    = users(:uiuc)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = UserPolicy.new(context, @object_user)
    assert !policy.submitted_item_results?
  end

  test "submitted_item_results?() authorizes sysadmins" do
    user    = users(:local_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = UserPolicy.new(context, @object_user)
    assert policy.submitted_item_results?
  end

  test "submitted_item_results?() respects role limits" do
    # sysadmin user limited to an insufficient role
    user    = users(:local_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::LOGGED_IN)
    policy  = UserPolicy.new(context, @object_user)
    assert !policy.submitted_item_results?
  end

  # update_properties?()

  test "update_properties?() returns false with a nil request context" do
    policy = UserPolicy.new(nil, @object_user)
    assert !policy.update_properties?
  end

  test "update_properties?() does not authorize non-sysadmins" do
    user    = users(:uiuc)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = UserPolicy.new(context, @object_user)
    assert !policy.update_properties?
  end

  test "update_properties?() authorizes the same user" do
    user    = users(:norights)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy = UserPolicy.new(context, context.user)
    assert policy.update_properties?
  end

  test "update_properties?() authorizes sysadmins" do
    user    = users(:local_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy = UserPolicy.new(context, @object_user)
    assert policy.update_properties?
  end

  test "update_properties?() respects role limits" do
    # sysadmin user limited to an insufficient role
    user    = users(:local_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::LOGGED_IN)
    policy  = UserPolicy.new(context, @object_user)
    assert !policy.update_properties?
  end

end
