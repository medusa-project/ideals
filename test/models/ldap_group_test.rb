require 'test_helper'

class LdapGroupTest < ActiveSupport::TestCase

  setup do
    @instance = ldap_groups(:sysadmin)
  end

  # short_name()

  test "short_name() returns a correct value" do
    @instance.urn = "urn:system admin"
    assert_equal "System Admin", @instance.short_name
  end

  # to_s()

  test "to_s() returns a correct value" do
    assert_equal @instance.urn, @instance.to_s
  end

  # urn

  test "urn cannot be blank" do
    assert_raises ActiveRecord::RecordInvalid do
      LdapGroup.create!(urn: "")
    end
  end

  test "urn must be unique" do
    assert_raises ActiveRecord::RecordNotUnique do
      LdapGroup.create!(urn: @instance.urn)
    end
  end

end
