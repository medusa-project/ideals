require 'test_helper'

class LocalIdentityPolicyTest < ActiveSupport::TestCase

  setup do
    @identity = local_identities(:norights)
  end

  # new_password?()

  test "new_password?() returns true with a nil user" do
    policy = LocalIdentityPolicy.new(nil, @identity)
    assert policy.new_password?
  end

  test "new_password?() authorizes everyone" do
    context = UserContext.new(users(:norights), Role::NO_LIMIT)
    policy  = LocalIdentityPolicy.new(context, @identity)
    assert policy.new_password?
  end

  # register?()

  test "register?() returns true with a nil user" do
    policy = LocalIdentityPolicy.new(nil, @identity)
    assert policy.register?
  end

  test "register?() authorizes everyone" do
    context = UserContext.new(users(:norights), Role::NO_LIMIT)
    policy  = LocalIdentityPolicy.new(context, @identity)
    assert policy.register?
  end

  # reset_password?()

  test "reset_password?() returns true with a nil user" do
    policy = LocalIdentityPolicy.new(nil, @identity)
    assert policy.reset_password?
  end

  test "reset_password?() authorizes everyone" do
    context = UserContext.new(users(:norights), Role::NO_LIMIT)
    policy  = LocalIdentityPolicy.new(context, @identity)
    assert policy.reset_password?
  end

end
