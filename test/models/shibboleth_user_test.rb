require 'test_helper'

class ShibbolethUserTest < ActiveSupport::TestCase

  setup do
    @instance = users(:shibboleth)
    assert @instance.valid?
  end

  # netid()

  test "netid() returns the NetID" do
    assert_equal "shib", @instance.netid
  end

  # sysadmin?()

  test "sysadmin?() returns true when the user is a member of the sysadmin AD group" do
    # TODO: figure out how to best test this
  end

  test "sysadmin?() returns false when the user is not a member of the sysadmin AD group" do
    assert !@instance.sysadmin?
  end

end