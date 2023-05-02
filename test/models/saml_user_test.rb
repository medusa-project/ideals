require 'test_helper'

class SamlUserTest < ActiveSupport::TestCase

  def self.auth_hash
    {
      provider: "saml",
      uid: "TheUID",
      info: {
        name: nil,
        email: nil,
        first_name: nil,
        last_name: nil
      },
      credentials: {},
      extra: {
        raw_info: {
          attributes: {
            "urn:oid:1.3.6.1.4.1.5923.1.1.1.9": [
              "member@southwest.edu"
            ],
            emailAddress: [
              "user@southwest.edu"
            ],
            "urn:mace:eduserv.org.uk:athens:attribute-def:federation:1.0:identifier": [
              "urn:mace:eduserv.org.uk:athens:federation:uk"
            ],
            "urn:oid:1.3.6.1.4.1.5923.1.1.1.1": [
              "member"
            ],
            "http://eduserv.org.uk/federation/attributes/1.0/organisationid": [
              "southwest.edu"
            ],
            "urn:oid:1.3.6.1.4.1.5923.1.1.1.10": [
              "https://idp.southwest.edu/openathens/ejurg5iical0uvrqv4oo0aql7"
            ],
            fingerprint: nil
          }
        },
        session_index: "9405916a4fc24a6c4057d6d5cf5dc9721af145739489bde3d7ce22ce00bc6a8e",
        response_object: {
          errors: [],
          options: {
            # a million different things in here that we aren't using
          }
        }
      }
    }.deep_stringify_keys
  end

  # from_omniauth()

  test "from_omniauth() returns an existing instance if a corresponding
  SamlUser already exists" do
    auth_hash = {
      provider: "saml",
      uid: "saml@southwest.edu",
      info: {
        name: nil,
        email: nil,
        first_name: nil,
        last_name: nil
      },
      credentials: {},
      extra: {
        raw_info: {
          attributes: {
            "urn:oid:1.3.6.1.4.1.5923.1.1.1.9": [
              "member@southwest.edu"
            ],
            emailAddress: [
              "saml@southwest.edu"
            ],
            "urn:mace:eduserv.org.uk:athens:attribute-def:federation:1.0:identifier": [
              "urn:mace:eduserv.org.uk:athens:federation:uk"
            ],
            "urn:oid:1.3.6.1.4.1.5923.1.1.1.1": [
              "member"
            ],
            "http://eduserv.org.uk/federation/attributes/1.0/organisationid": [
              "southwest.edu"
            ],
            "urn:oid:1.3.6.1.4.1.5923.1.1.1.10": [
              "https://idp.rmu.edu/openathens/ejurg5iical0uvrqv4oo0aql7"
            ],
            fingerprint: nil
          }
        },
        session_index: "9405916a4fc24a6c4057d6d5cf5dc9721af145739489bde3d7ce22ce00bc6a8e",
        response_object: {
          errors: [],
          options: {
            # a million different things in here that we aren't using
          }
        }
      }
    }.deep_stringify_keys
    saml_user = users(:southwest_saml)
    user      = SamlUser.from_omniauth(auth_hash)
    assert_same saml_user.id, user.id
  end

  test "from_omniauth() returns a new instance if a corresponding SamlUser
  does not already exist" do
    assert_nil SamlUser.find_by_uid("new")
    assert_not_nil SamlUser.from_omniauth(self.class.auth_hash)
  end

  test "from_omniauth() sets correct properties" do
    user = SamlUser.from_omniauth(self.class.auth_hash)
    assert_equal "TheUID", user.uid
    assert_nil user.name
    assert_equal "user@southwest.edu", user.email
    assert_nil user.phone
    assert_equal institutions(:southwest), user.institution
  end

  # sysadmin?()

  # TODO: test this

end