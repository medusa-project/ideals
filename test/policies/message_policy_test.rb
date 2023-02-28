require 'test_helper'

class MessagePolicyTest < ActiveSupport::TestCase

  setup do
    @user = users(:example)
  end

  # index?()

  test "index?() returns false with a nil user" do
    policy = MessagePolicy.new(nil, Message)
    assert !policy.index?
  end

  test "index?() does not authorize non-sysadmins" do
    user    = users(:example)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = MessagePolicy.new(context, Message)
    assert !policy.index?
  end

  test "index?() authorizes sysadmins" do
    user    = users(:example_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = MessagePolicy.new(context, Message)
    assert policy.index?
  end

  test "index?() respects role limits" do
    # sysadmin user limited to an insufficient role
    user    = users(:example_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::LOGGED_IN)
    policy  = MessagePolicy.new(context, Message)
    assert !policy.index?
  end

  # resend?()

  test "resend?() returns false with a nil user" do
    policy = MessagePolicy.new(nil, Message)
    assert !policy.resend?
  end

  test "resend?() does not authorize non-sysadmins" do
    user    = users(:example)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = MessagePolicy.new(context, Message)
    assert !policy.resend?
  end

  test "resend?() authorizes sysadmins" do
    user    = users(:example_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = MessagePolicy.new(context, Message)
    assert policy.resend?
  end

  test "resend?() respects role limits" do
    # sysadmin user limited to an insufficient role
    user    = users(:example_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::LOGGED_IN)
    policy  = MessagePolicy.new(context, Message)
    assert !policy.resend?
  end

  # show?()

  test "show?() returns false with a nil user" do
    policy = MessagePolicy.new(nil, Message)
    assert !policy.show?
  end

  test "show?() does not authorize non-sysadmins" do
    user    = users(:example)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = MessagePolicy.new(context, Message)
    assert !policy.show?
  end

  test "show?() authorizes sysadmins" do
    user    = users(:example_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = MessagePolicy.new(context, Message)
    assert policy.show?
  end

  test "show?() respects role limits" do
    # sysadmin user limited to an insufficient role
    user    = users(:example_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::LOGGED_IN)
    policy  = MessagePolicy.new(context, Message)
    assert !policy.show?
  end

end
