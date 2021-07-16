require 'test_helper'

class LocalIdentityPolicyTest < ActiveSupport::TestCase

  setup do
    @identity = local_identities(:norights)
  end

  # activate?()

  test "activate?() returns true with a nil user" do
    policy = LocalIdentityPolicy.new(nil, @identity)
    assert policy.activate?
  end

  test "activate?() authorizes everyone" do
    user    = users(:norights)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::NO_LIMIT)
    policy  = LocalIdentityPolicy.new(context, @identity)
    assert policy.activate?
  end

  # edit_password?()

  test "edit_password?() returns false with a nil request context" do
    policy = LocalIdentityPolicy.new(nil, @identity)
    assert !policy.edit_password?
  end

  test "edit_password?() does not authorize non-sysadmins other than the user
  being edited" do
    user    = users(:norights2)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::NO_LIMIT)
    policy  = LocalIdentityPolicy.new(context, @identity)
    assert !policy.edit_password?
  end

  test "edit_password?() does not authorize sysadmins other than the user
  being edited" do
    user    = users(:local_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::NO_LIMIT)
    policy  = LocalIdentityPolicy.new(context, @identity)
    assert !policy.edit_password?
  end

  test "edit_password?() authorizes the same user as the one being edited" do
    user    = users(:norights)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::NO_LIMIT)
    policy  = LocalIdentityPolicy.new(context, @identity)
    assert policy.edit_password?
  end

  test "edit_password?() respects role limits" do
    # sysadmin user limited to an insufficient role
    user    = users(:local_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::LOGGED_IN)
    policy  = LocalIdentityPolicy.new(context, @identity)
    assert !policy.edit_password?
  end

  # new_password?()

  test "new_password?() returns true with a nil user" do
    policy = LocalIdentityPolicy.new(nil, @identity)
    assert policy.new_password?
  end

  test "new_password?() authorizes everyone" do
    user    = users(:norights)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::NO_LIMIT)
    policy  = LocalIdentityPolicy.new(context, @identity)
    assert policy.new_password?
  end

  # register?()

  test "register?() returns true with a nil user" do
    policy = LocalIdentityPolicy.new(nil, @identity)
    assert policy.register?
  end

  test "register?() authorizes everyone" do
    user    = users(:norights)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::NO_LIMIT)
    policy  = LocalIdentityPolicy.new(context, @identity)
    assert policy.register?
  end

  # reset_password?()

  test "reset_password?() returns true with a nil user" do
    policy = LocalIdentityPolicy.new(nil, @identity)
    assert policy.reset_password?
  end

  test "reset_password?() authorizes everyone" do
    user    = users(:norights)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::NO_LIMIT)
    policy  = LocalIdentityPolicy.new(context, @identity)
    assert policy.reset_password?
  end

  # update?()

  test "update?() returns true with a nil user" do
    policy = LocalIdentityPolicy.new(nil, @identity)
    assert policy.update?
  end

  test "update?() authorizes everyone" do
    user    = users(:norights)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::NO_LIMIT)
    policy  = LocalIdentityPolicy.new(context, @identity)
    assert policy.update?
  end

  # update_password?()

  test "update_password?() returns false with a nil request context" do
    policy = LocalIdentityPolicy.new(nil, @identity)
    assert !policy.update_password?
  end

  test "update_password?() does not authorize non-sysadmins other than the user
  being updated" do
    user    = users(:norights2)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::NO_LIMIT)
    policy = LocalIdentityPolicy.new(context, @identity)
    assert !policy.update_password?
  end

  test "update_password?() does not authorize sysadmins other than the user
  being updated" do
    user    = users(:local_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::NO_LIMIT)
    policy = LocalIdentityPolicy.new(context, @identity)
    assert !policy.update_password?
  end

  test "update_password?() authorizes the same user" do
    user    = users(:norights)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::NO_LIMIT)
    policy = LocalIdentityPolicy.new(context, @identity)
    assert policy.update_password?
  end

  test "update_password?() respects role limits" do
    # sysadmin user limited to an insufficient role
    user    = users(:local_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::LOGGED_IN)
    policy  = LocalIdentityPolicy.new(context, @identity)
    assert !policy.update_password?
  end

end
