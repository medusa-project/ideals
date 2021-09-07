require 'test_helper'

class FileFormatPolicyTest < ActiveSupport::TestCase

  setup do
    @user = users(:norights)
  end

  # index?()

  test "index?() returns false with a nil user" do
    policy = FileFormatPolicy.new(nil, FileFormat)
    assert !policy.index?
  end

  test "index?() does not authorize non-sysadmins" do
    user    = users(:norights)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy = FileFormatPolicy.new(context, FileFormat)
    assert !policy.index?
  end

  test "index?() authorizes sysadmins" do
    user    = users(:local_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = FileFormatPolicy.new(context, FileFormat)
    assert policy.index?
  end

  test "index?() respects role limits" do
    # sysadmin user limited to an insufficient role
    user    = users(:local_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::LOGGED_IN)
    policy  = FileFormatPolicy.new(context, FileFormat)
    assert !policy.index?
  end

end
