require 'test_helper'

class ShibbolethUserTest < ActiveSupport::TestCase

  setup do
    @instance = users(:uiuc)
    assert @instance.valid?
  end

  def self.auth_hash
    {
        provider: "shibboleth",
        uid: "example@illinois.edu",
        info: {
            name: nil,
            email: "example@illinois.edu"
        },
        credentials: {},
        extra: {
            raw_info: {
                eppn: "example@illinois.edu",
                "unscoped-affiliation": "member;staff;employee",
                uid: "example",
                sn: "Example",
                "org-dn": Institution::UIUC_ORG_DN,
                nickname: "",
                givenName: "Example",
                member: "urn:mace:uiuc.edu:urbana:library:units:ideals:library ideals admin"
            }
        }
    }.deep_stringify_keys
  end

  # from_omniauth()

  test "from_omniauth() returns an existing instance if a corresponding
  ShibbolethUser already exists" do
    # TODO: figure out how to test this
  end

  test "from_omniauth() returns a new instance if a corresponding
  ShibbolethUser does not already exist" do
    assert_nil ShibbolethUser.find_by_uid("example@illinois.edu")
    user = ShibbolethUser.from_omniauth(self.class.auth_hash)
    assert_equal "example@illinois.edu", user.uid
    assert_equal "example@illinois.edu", user.email
    assert_equal Institution::UIUC_ORG_DN, user.org_dn
  end

  test "from_omniauth() creates corresponding LdapGroups for all of the user's
  LDAP groups" do
    LdapGroup.destroy_all
    ShibbolethUser.from_omniauth(self.class.auth_hash)
    assert_equal 1, LdapGroup.count
  end

  # netid()

  test "netid() returns the NetID" do
    assert_equal "shib", @instance.netid
  end

  # sysadmin?()

  test "sysadmin?() returns true when the user is a member of an LDAP group
  included in the sysadmin user group" do
    @instance = users(:uiuc_admin)
    assert @instance.sysadmin?
  end

  test "sysadmin?() returns false when the user is not a member of the sysadmin
  LDAP group" do
    assert !@instance.sysadmin?
  end

end