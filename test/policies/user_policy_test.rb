require 'test_helper'

class UserPolicyTest < ActiveSupport::TestCase

  setup do
    @object_user = users(:norights)
  end

  # edit_privileges?()

  test "edit_privileges?() returns false with a nil user context" do
    policy = UserPolicy.new(nil, @object_user)
    assert !policy.edit_privileges?
  end

  test "edit_privileges?() does not authorize non-sysadmins" do
    context = UserContext.new(users(:norights), Role::NO_LIMIT)
    policy  = UserPolicy.new(context, @object_user)
    assert !policy.edit_privileges?
  end

  test "edit_privileges?() authorizes sysadmins" do
    context = UserContext.new(users(:local_sysadmin), Role::NO_LIMIT)
    policy = UserPolicy.new(context, @object_user)
    assert policy.edit_privileges?
  end

  test "edit_privileges?() respects role limits" do
    # sysadmin user limited to an insufficient role
    context = UserContext.new(users(:local_sysadmin), Role::LOGGED_IN)
    policy  = UserPolicy.new(context, @object_user)
    assert !policy.edit_privileges?
  end

  # edit_properties?()

  test "edit_properties?() returns false with a nil user context" do
    policy = UserPolicy.new(nil, @object_user)
    assert !policy.edit_properties?
  end

  test "edit_properties?() does not authorize non-sysadmins other than the one
  being edited" do
    context = UserContext.new(users(:shibboleth), Role::NO_LIMIT)
    policy  = UserPolicy.new(context, @object_user)
    assert !policy.edit_properties?
  end

  test "edit_properties?() authorizes the same user as the one being edited" do
    context = UserContext.new(users(:norights), Role::NO_LIMIT)
    policy  = UserPolicy.new(context, context.user)
    assert policy.edit_properties?
  end

  test "edit_properties?() authorizes sysadmins" do
    context = UserContext.new(users(:local_sysadmin), Role::NO_LIMIT)
    policy = UserPolicy.new(context, @object_user)
    assert policy.edit_properties?
  end

  test "edit_properties?() respects role limits" do
    # sysadmin user limited to an insufficient role
    context = UserContext.new(users(:local_sysadmin), Role::LOGGED_IN)
    policy  = UserPolicy.new(context, @object_user)
    assert !policy.edit_properties?
  end

  # index?()

  test "index?() returns false with a nil user context" do
    policy = UserPolicy.new(nil, User)
    assert !policy.index?
  end

  test "index?() does not authorize non-sysadmins" do
    context = UserContext.new(users(:norights), Role::NO_LIMIT)
    policy  = UserPolicy.new(context, User)
    assert !policy.index?
  end

  test "index?() authorizes sysadmins" do
    context = UserContext.new(users(:local_sysadmin), Role::NO_LIMIT)
    policy = UserPolicy.new(context, User)
    assert policy.index?
  end

  test "index?() respects role limits" do
    # sysadmin user limited to an insufficient role
    context = UserContext.new(users(:local_sysadmin), Role::LOGGED_IN)
    policy  = UserPolicy.new(context, @object_user)
    assert !policy.index?
  end

  # invite?()

  test "invite?() returns false with a nil user context" do
    policy = UserPolicy.new(nil, @object_user)
    assert !policy.invite?
  end

  test "invite?() does not authorize non-sysadmins" do
    context = UserContext.new(users(:norights), Role::NO_LIMIT)
    policy = UserPolicy.new(context, @object_user)
    assert !policy.invite?
  end

  test "invite?() authorizes sysadmins" do
    context = UserContext.new(users(:local_sysadmin), Role::NO_LIMIT)
    policy = UserPolicy.new(context, @object_user)
    assert policy.invite?
  end

  test "invite?() respects role limits" do
    # sysadmin user limited to an insufficient role
    context = UserContext.new(users(:local_sysadmin), Role::LOGGED_IN)
    policy  = UserPolicy.new(context, @object_user)
    assert !policy.invite?
  end

  # show?()

  test "show?() returns false with a nil user context" do
    policy = UserPolicy.new(nil, @object_user)
    assert !policy.show?
  end

  test "show?() does not authorize non-sysadmins" do
    context = UserContext.new(users(:shibboleth), Role::NO_LIMIT)
    policy = UserPolicy.new(context, @object_user)
    assert !policy.show?
  end

  test "show?() authorizes sysadmins" do
    context = UserContext.new(users(:local_sysadmin), Role::NO_LIMIT)
    policy = UserPolicy.new(context, @object_user)
    assert policy.show?
  end

  test "show?() respects role limits" do
    # sysadmin user limited to an insufficient role
    context = UserContext.new(users(:local_sysadmin), Role::LOGGED_IN)
    policy  = UserPolicy.new(context, @object_user)
    assert !policy.show?
  end

  # update_privileges?()

  test "update_privileges?() returns false with a nil user context" do
    policy = UserPolicy.new(nil, @object_user)
    assert !policy.update_privileges?
  end

  test "update_privileges?() does not authorize non-sysadmins" do
    context = UserContext.new(users(:norights), Role::NO_LIMIT)
    policy = UserPolicy.new(context, @object_user)
    assert !policy.update_privileges?
  end

  test "update_privileges?() authorizes sysadmins" do
    context = UserContext.new(users(:local_sysadmin), Role::NO_LIMIT)
    policy = UserPolicy.new(context, @object_user)
    assert policy.update_privileges?
  end

  test "update_privileges?() respects role limits" do
    # sysadmin user limited to an insufficient role
    context = UserContext.new(users(:local_sysadmin), Role::LOGGED_IN)
    policy  = UserPolicy.new(context, @object_user)
    assert !policy.update_privileges?
  end

  # update_properties?()

  test "update_properties?() returns false with a nil user context" do
    policy = UserPolicy.new(nil, @object_user)
    assert !policy.update_properties?
  end

  test "update_properties?() does not authorize non-sysadmins" do
    context = UserContext.new(users(:shibboleth), Role::NO_LIMIT)
    policy = UserPolicy.new(context, @object_user)
    assert !policy.update_properties?
  end

  test "update_properties?() authorizes the same user" do
    context = UserContext.new(users(:norights), Role::NO_LIMIT)
    policy = UserPolicy.new(context, context.user)
    assert policy.update_properties?
  end

  test "update_properties?() authorizes sysadmins" do
    context = UserContext.new(users(:local_sysadmin), Role::NO_LIMIT)
    policy = UserPolicy.new(context, @object_user)
    assert policy.update_properties?
  end

  test "update_properties?() respects role limits" do
    # sysadmin user limited to an insufficient role
    context = UserContext.new(users(:local_sysadmin), Role::LOGGED_IN)
    policy  = UserPolicy.new(context, @object_user)
    assert !policy.update_properties?
  end

end
