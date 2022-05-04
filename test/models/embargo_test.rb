require 'test_helper'

class EmbargoTest < ActiveSupport::TestCase

  setup do
    @instance = embargoes(:one)
  end

  # as_change_hash()

  test "as_change_hash() returns the correct structure" do
    actual = @instance.as_change_hash
    assert_equal "ALL_ACCESS", actual['kind']
    assert_not_nil actual['expires_at']
    assert_not_nil actual['item_id']
    assert !actual['perpetual']
    assert_not_nil actual['expires_at']
    assert_nil actual['reason']
  end

  # as_indexed_json()

  test "as_indexed_json() returns the correct structure" do
    expires = Time.now.utc + 1.hour
    actual  = @instance.as_indexed_json
    assert_equal Embargo::Kind::ALL_ACCESS, actual['i_kind']
    assert_equal expires.year, Time.parse(actual['d_expires_at']).year
    assert_equal expires.month, Time.parse(actual['d_expires_at']).month
    assert_equal expires.day, Time.parse(actual['d_expires_at']).day
  end

  # exempt?()

  test "exempt?() returns false when the given user is not exempt from the
  embargo" do
    user    = users(:norights)
    assert !@instance.exempt?(user)
  end

  test "exempt?() returns true when the given user is exempt from the embargo" do
    user    = users(:local_sysadmin)
    assert !@instance.exempt?(user)
    @instance.user_groups << user_groups(:sysadmin)
    assert @instance.exempt?(user)
  end

  # expires_at

  test "expires_at cannot be in the past if perpetual is false" do
    item = items(:item1)
    e = item.embargoes.build(expires_at: 1.minute.ago,
                             perpetual:  false,
                             kind:       Embargo::Kind::ALL_ACCESS)
    assert !e.valid?
  end

  # expires_at

  test "expires_at can be in the past if perpetual is true" do
    item = items(:item1)
    e = item.embargoes.build(expires_at: 1.minute.ago,
                             perpetual:  true,
                             kind:       Embargo::Kind::ALL_ACCESS)
    assert e.valid?
  end

  # kind

  test "kind must be one of the Kind constant values" do
    @instance.kind = Embargo::Kind::ALL_ACCESS
    assert @instance.valid?

    @instance.kind = 22
    assert !@instance.valid?
  end

end
