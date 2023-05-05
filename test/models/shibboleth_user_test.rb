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
            name: "Shib Boleth, Esq.",
            email: "example@illinois.edu"
        },
        credentials: {},
        extra: {
            raw_info: {
                eppn: "example@illinois.edu",
                "unscoped-affiliation": "member;staff;employee",
                uid: "example",
                sn: "Boleth",
                "org-dn": "o=University of Illinois at Urbana-Champaign,dc=uiuc,dc=edu",
                nickname: "",
                givenName: "Shib",
                telephoneNumber: "(888) 555-5555",
                member: "urn:mace:uiuc.edu:urbana:library:units:ideals:library ideals admin",
                iTrustAffiliation: "member;staff;employee",
                departmentCode: "Example Department",
                programCode: nil,
                levelCode: nil
            }
        }
    }.deep_stringify_keys
  end

  # from_omniauth()

  test "from_omniauth() returns an existing instance if a corresponding
  ShibbolethUser already exists" do
    auth_hash = {
      provider: "shibboleth",
      uid: "shib@illinois.edu",
      info: {
        name: "Shib Boleth, Esq.",
        email: "shib@illinois.edu"
      },
      credentials: {},
      extra: {
        raw_info: {
          eppn: "shib@illinois.edu",
          "unscoped-affiliation": "member;staff;employee",
          uid: "shib@illinois.edu",
          sn: "Example",
          "org-dn": "o=University of Illinois at Urbana-Champaign,dc=uiuc,dc=edu",
          nickname: "",
          givenName: "Example",
          member: "urn:mace:uiuc.edu:urbana:library:units:ideals:library ideals admin",
          iTrustAffiliation: "member;staff;employee",
          departmentCode: nil,
          programCode: nil,
          levelCode: nil
        }
      }
    }.deep_stringify_keys
    shib_user = users(:uiuc)
    user      = ShibbolethUser.from_omniauth(auth_hash)
    assert_same shib_user.id, user.id
  end

  # N.B.: non-UIUC users have a blank org DN, and they all get assigned to the
  # UIUC institution. This is intended to be temporary until all of UIS's stuff
  # gets migrated into the UIS institution and its users are transitioned to
  # local identities.
  test "from_omniauth() works with non-UIUC users" do
    auth_hash = {
      provider: "shibboleth",
      uid: "shib@southwest.edu",
      info: {
        name: "Southwest U Shibboleth User",
        email: "shib@southwest.edu"
      },
      credentials: {
      },
      extra: {
        raw_info: {
          eppn: "shib@southwest.edu",
          "unscoped-affiliation": "faculty;affiliate;staff;employee;member",
          uid: "shib",
          sn: "User",
          "org-dn": "",
          nickname: "Shib",
          givenName: "Shib",
          iTrustAffiliation: "",
          departmentName: "",
          programCode: "",
          levelCode: ""
        }
      }
    }.deep_stringify_keys
    shib_user = users(:southwest_shibboleth)
    user      = ShibbolethUser.from_omniauth(auth_hash)
    assert_same shib_user.id, user.id
    assert_equal institutions(:uiuc), user.institution
  end

  test "from_omniauth() returns a new instance if a corresponding
  ShibbolethUser does not already exist" do
    assert_nil ShibbolethUser.find_by_email("example@illinois.edu")
    assert_not_nil ShibbolethUser.from_omniauth(self.class.auth_hash)
  end

  test "from_omniauth() sets correct properties" do
    user = ShibbolethUser.from_omniauth(self.class.auth_hash)
    assert_equal "Shib Boleth", user.name
    assert_equal "example@illinois.edu", user.email
    assert_equal "(888) 555-5555", user.phone
    assert_equal "o=University of Illinois at Urbana-Champaign,dc=uiuc,dc=edu",
                 user.org_dn
    assert_equal institutions(:uiuc), user.institution
    assert_equal "Example Department", user.department.name
    assert_equal Affiliation.find_by_key(Affiliation::FACULTY_STAFF_KEY),
                 user.affiliation
  end

  # no_omniauth()

  # TODO: test this

  # netid()

  test "netid() returns the NetID" do
    assert_equal "shib", @instance.netid
  end

  # sysadmin?()

  test "sysadmin?() returns true when the user is a member of an LDAP group
  included in the sysadmin user group" do
    @instance = users(:example_sysadmin)
    assert @instance.sysadmin?
  end

  test "sysadmin?() returns false when the user is not a member of the sysadmin
  LDAP group" do
    assert !@instance.sysadmin?
  end

end