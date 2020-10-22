require 'test_helper'

class LdapGroupTest < ActiveSupport::TestCase

  setup do
    @instance = ldap_groups(:sysadmin)
  end

  # name

  test "name cannot be blank" do
    assert_raises ActiveRecord::RecordInvalid do
      LdapGroup.create!(name: "")
    end
  end

  test "name must be unique" do
    assert_raises ActiveRecord::RecordNotUnique do
      LdapGroup.create!(name: @instance.name)
    end
  end

end
