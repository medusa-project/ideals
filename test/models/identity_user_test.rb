require "test_helper"

class IdentityUserTest < ActiveSupport::TestCase

  setup do
    @instance = users(:norights)
  end

  # destroy()

  test "destroy() destroys the associated Identity" do
    identity = @instance.identity
    @instance.destroy!

    assert_raises ActiveRecord::RecordNotFound do
      identity.reload
    end
  end

  # identity()

  test "identity() returns the associated Identity" do
    assert_equal identities(:norights), @instance.identity
  end

  # sysadmin?()

  test "sysadmin?() returns true when the user is sysadmin" do
    assert users(:admin).sysadmin?
  end

  test "sysadmin?() returns false when the user is not a sysadmin" do
    assert !@instance.sysadmin?
  end

end
