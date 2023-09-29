require 'test_helper'

class UsagePolicyTest < ActiveSupport::TestCase

  # files?()

  test "files?() returns false with a nil user" do
    policy = UsagePolicy.new(nil, Usage)
    assert !policy.files?
  end

  test "files?() does not authorize non-sysadmins" do
    user    = users(:southwest)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy = UsagePolicy.new(context, Usage)
    assert !policy.files?
  end

  test "files?() authorizes sysadmins" do
    user    = users(:southwest_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = UsagePolicy.new(context, Usage)
    assert policy.files?
  end

  test "files?() respects role limits" do
    # sysadmin user limited to an insufficient role
    user    = users(:southwest_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::LOGGED_IN)
    policy  = UsagePolicy.new(context, Usage)
    assert !policy.files?
  end

  # index?()

  test "index?() returns false with a nil user" do
    policy = UsagePolicy.new(nil, Usage)
    assert !policy.index?
  end

  test "index?() does not authorize non-sysadmins" do
    user    = users(:southwest)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy = UsagePolicy.new(context, Usage)
    assert !policy.index?
  end

  test "index?() authorizes sysadmins" do
    user    = users(:southwest_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = UsagePolicy.new(context, Usage)
    assert policy.index?
  end

  test "index?() respects role limits" do
    # sysadmin user limited to an insufficient role
    user    = users(:southwest_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::LOGGED_IN)
    policy  = UsagePolicy.new(context, Usage)
    assert !policy.index?
  end

  # items?()

  test "items?() returns false with a nil user" do
    policy = UsagePolicy.new(nil, Usage)
    assert !policy.items?
  end

  test "items?() does not authorize non-sysadmins" do
    user    = users(:southwest)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy = UsagePolicy.new(context, Usage)
    assert !policy.items?
  end

  test "items?() authorizes sysadmins" do
    user    = users(:southwest_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = UsagePolicy.new(context, Usage)
    assert policy.items?
  end

  test "items?() respects role limits" do
    # sysadmin user limited to an insufficient role
    user    = users(:southwest_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::LOGGED_IN)
    policy  = UsagePolicy.new(context, Usage)
    assert !policy.items?
  end

end
