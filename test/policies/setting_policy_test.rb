require 'test_helper'

class SettingPolicyTest < ActiveSupport::TestCase

  # index?()

  test "index?() returns false with a nil user" do
    policy = SettingPolicy.new(nil, Setting)
    assert !policy.index?
  end

  test "index?() does not authorize non-sysadmins" do
    user    = users(:example)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = SettingPolicy.new(context, Setting)
    assert !policy.index?
  end

  test "index?() authorizes sysadmins" do
    user    = users(:example_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = SettingPolicy.new(context, Setting)
    assert policy.index?
  end

  test "index?() respects role limits" do
    # sysadmin user limited to an insufficient role
    user    = users(:example_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::LOGGED_IN)
    policy  = SettingPolicy.new(context, Setting)
    assert !policy.index?
  end
  
  # update?()

  test "update?() returns false with a nil user" do
    policy = SettingPolicy.new(nil, @item)
    assert !policy.update?
  end

  test "update?() does not authorize non-sysadmins" do
    user    = users(:example)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = SettingPolicy.new(context, @item)
    assert !policy.update?
  end

  test "update?() authorizes sysadmins" do
    user    = users(:example_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = SettingPolicy.new(context, @item)
    assert policy.update?
  end

  test "update?() respects role limits" do
    # sysadmin user limited to an insufficient role
    user    = users(:example_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::LOGGED_IN)
    policy  = SettingPolicy.new(context, @item)
    assert !policy.update?
  end

end
