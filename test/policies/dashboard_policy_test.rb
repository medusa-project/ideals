require 'test_helper'

class DashboardPolicyTest < ActiveSupport::TestCase

  # index?()

  test "index?() returns false with a nil user" do
    policy = DashboardPolicy.new(nil, :dashboard)
    assert !policy.index?
  end

  test "index?() authorizes logged-in users" do
    context = UserContext.new(users(:norights), Role::NO_LIMIT)
    policy  = DashboardPolicy.new(context, :dashboard)
    assert policy.index?
  end

  test "index?() respects role limits" do
    # sysadmin user limited to an insufficient role
    context = UserContext.new(users(:admin), Role::LOGGED_OUT)
    policy  = DashboardPolicy.new(context, :dashboard)
    assert !policy.index?
  end

end
