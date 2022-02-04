require 'test_helper'

class EmbargoTest < ActiveSupport::TestCase

  # as_indexed_json()

  test "as_indexed_json() returns the correct structure" do
    expires = Time.now.utc + 1.hour
    actual  = embargoes(:one).as_indexed_json
    assert(actual['b_download'])
    assert(actual['b_full_access'])
    assert_equal(expires.year, Time.parse(actual['d_expires_at']).year)
    assert_equal(expires.month, Time.parse(actual['d_expires_at']).month)
    assert_equal(expires.day, Time.parse(actual['d_expires_at']).day)
  end

  # validate()

  test "validate() does not allow expires_at to be in the past" do
    item = items(:item1)
    e =item.embargoes.build(expires_at:  1.minute.ago,
                            download:    true,
                            full_access: true)
    assert !e.valid?
  end

  test "validate() requires at least one restriction" do
    item = items(:item1)
    e = item.embargoes.build(expires_at:  Time.now + 1.hour,
                             download:    false,
                             full_access: false)
    assert !e.valid?

    e = item.embargoes.build(expires_at:  Time.now + 1.hour,
                             download:    true,
                             full_access: false)
    assert e.valid?

    e = item.embargoes.build(expires_at:  Time.now + 1.hour,
                             download:    false,
                             full_access: true)
    assert e.valid?
  end

end
