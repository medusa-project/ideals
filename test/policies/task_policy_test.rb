require 'test_helper'

class TaskPolicyTest < ActiveSupport::TestCase

  setup do
    @user = users(:norights)
  end

  # index?()

  test "index?() returns false with a nil user" do
    policy = TaskPolicy.new(nil, Task)
    assert !policy.index?
  end

  test "index?() does not authorize non-sysadmins" do
    user    = users(:norights)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy = TaskPolicy.new(context, Task)
    assert !policy.index?
  end

  test "index?() authorizes sysadmins" do
    user    = users(:local_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = TaskPolicy.new(context, Task)
    assert policy.index?
  end

  test "index?() respects role limits" do
    # sysadmin user limited to an insufficient role
    user    = users(:local_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::LOGGED_IN)
    policy  = TaskPolicy.new(context, Task)
    assert !policy.index?
  end

  # show?()

  test "show?() returns false with a nil user" do
    policy = TaskPolicy.new(nil, @profile)
    assert !policy.show?
  end

  test "show?() does not authorize non-sysadmins" do
    user    = users(:norights)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = TaskPolicy.new(context, @profile)
    assert !policy.show?
  end

  test "show?() authorizes sysadmins" do
    user    = users(:local_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = TaskPolicy.new(context, @profile)
    assert policy.show?
  end

  test "show?() respects role limits" do
    # sysadmin user limited to an insufficient role
    user    = users(:local_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::LOGGED_IN)
    policy  = TaskPolicy.new(context, @profile)
    assert !policy.show?
  end

end