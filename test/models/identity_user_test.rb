require "test_helper"

class IdentityUserTest < ActiveSupport::TestCase

  setup do
    @instance = users(:norights)
  end

  # sysadmin?()

  test "sysadmin?() returns true when the user is sysadmin" do
    assert users(:admin).sysadmin?
  end

  test "sysadmin?() returns false when the user is not a sysadmin" do
    assert !@instance.sysadmin?
  end

end
