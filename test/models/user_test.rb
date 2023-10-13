require 'test_helper'

class UserTest < ActiveSupport::TestCase

  setup do
    @user = users(:southwest)
  end

  SAML_AUTH_HASH = {
    provider: "saml",
    uid: "OpenAthensUser@example.org",
    info: {
      name: nil,
      email: nil,
      first_name: nil,
      last_name: nil
    },
    credentials: {},
    extra: {
      raw_info: OneLogin::RubySaml::Attributes.new(
        "urn:oid:1.3.6.1.4.1.5923.1.1.1.9": [
          "member@southwest.edu"
        ],
        emailAddress: [
          "OpenAthensUser@example.org"
        ],
        firstName: [
          "First"
        ],
        lastName: [
          "Last"
        ],
        "urn:mace:eduserv.org.uk:athens:attribute-def:federation:1.0:identifier": [
          "urn:mace:eduserv.org.uk:athens:federation:uk"
        ],
        "urn:oid:1.3.6.1.4.1.5923.1.1.1.1": [
          "member"
        ],
        "urn:oid:1.3.6.1.4.1.5923.1.1.1.10": [
          "https://idp.southwest.edu/openathens/ejurg5iical0uvrqv4oo0aql7"
        ],
        fingerprint: nil
      ),
      session_index: "9405916a4fc24a6c4057d6d5cf5dc9721af145739489bde3d7ce22ce00bc6a8e",
      response_object: nil
    }
  }

  SHIBBOLETH_AUTH_HASH = {
    provider: "shibboleth",
    uid: "ShibbolethUser@example.org",
    info: {
      name: "Shib Boleth",
      email: "ShibbolethUser@example.org"
    },
    credentials: {},
    extra: {
      raw_info: {
        eppn: "ShibbolethUser@example.org",
        "unscoped-affiliation": "member;staff;employee",
        uid: "example",
        sn: "Boleth",
        "org-dn": "o=Southeast University,dc=southeast,dc=edu",
        nickname: "",
        givenName: "Shib",
        telephoneNumber: "(888) 555-5555",
        member: "urn:mace:southeast.edu:urbana:library:units:ideals:library ideals admin",
        iTrustAffiliation: "member;staff;employee",
        departmentCode: "Example Department",
        programCode: nil,
        levelCode: nil
      }
    }
  }

  # create_local()

  test "create_local() creates a correct instance" do
    email       = "test@example.org"
    name        = "Testy Test"
    password    = LocalIdentity.random_password
    institution = institutions(:southwest)
    user        = User.create_local(email:       email,
                                    name:        name,
                                    password:    password,
                                    institution: institution)

    # check the Invitee
    invitee  = Invitee.find_by_email(email)
    assert_equal institution, invitee.institution
    assert invitee.approved?

    # check the LocalIdentity
    identity = invitee.identity
    assert_equal email, identity.email

    # check the User
    assert_equal identity, user.identity
    assert_equal email, user.email
    assert_equal name, user.name
    assert_nil user.phone
    assert_equal institution, user.institution
    assert !user.sysadmin?
  end

  # fetch_from_omniauth_local()

  test "fetch_from_omniauth_local() with a matching email returns the user" do
    user = users(:southwest)
    auth = {
      provider: "identity",
      uid:      user.email,
      info: {
        email: user.email
      }
    }
    assert_equal user, User.fetch_from_omniauth_local(auth)
  end

  test "fetch_from_omniauth_local() with a non-matching email returns nil" do
    auth = {
      provider: "identity",
      uid:      "bogus@example.edu",
      info: {
        email: "bogus@example.edu"
      }
    }
    assert_nil User.fetch_from_omniauth_local(auth)
  end

  # fetch_from_omniauth_saml()

  test "fetch_from_omniauth_saml() with a matching NameID returns the user" do
    user = users(:southwest)
    auth = {
      provider: "saml",
      uid: user.email,
      extra: {
        raw_info: OneLogin::RubySaml::Attributes.new()
      }
    }
    assert_equal user, User.fetch_from_omniauth_saml(auth,
                                                     email_location: Institution::SAMLEmailLocation::NAMEID)
  end

  test "fetch_from_omniauth_saml() with a matching email attribute returns the
  user" do
    user = users(:southwest)
    auth = {
      provider: "saml",
      extra: {
        raw_info: OneLogin::RubySaml::Attributes.new(
          emailAddress: [
            user.email
          ]
        )
      }
    }
    assert_equal user, User.fetch_from_omniauth_saml(auth,
                                                     email_location: Institution::SAMLEmailLocation::ATTRIBUTE)
  end

  test "fetch_from_omniauth_saml() with a non-matching email returns nil" do
    auth = {
      provider: "saml",
      extra: {
        raw_info: OneLogin::RubySaml::Attributes.new(
          emailAddress: [
            "bogus@example.org"
          ]
        )
      }
    }
    assert_nil User.fetch_from_omniauth_saml(auth,
                                             email_location: Institution::SAMLEmailLocation::ATTRIBUTE)
  end

  # fetch_from_omniauth_shibboleth()

  test "fetch_from_omniauth_shibboleth() with a matching email returns the user" do
    user = users(:southwest)
    auth = {
      provider: "shibboleth",
      info: {
        email: user.email
      }
    }
    assert_equal user, User.fetch_from_omniauth_shibboleth(auth)
  end

  test "fetch_from_omniauth_shibboleth() with a non-matching email returns nil" do
    auth = {
      provider: "shibboleth",
      info: {
        email: "bogus@example.org"
      }
    }
    assert_nil User.fetch_from_omniauth_shibboleth(auth)
  end

  # from_autocomplete_string()

  test "from_autocomplete_string() returns a user" do
    string = @user.to_autocomplete
    actual = User.from_autocomplete_string(string)
    assert_equal @user, actual
  end

  test "from_autocomplete_string() returns nil for no match" do
    string = "Bogus Bogus (bogus.example.org)"
    assert_nil User.from_autocomplete_string(string)
  end

  # from_omniauth()

  test "from_omniauth() returns nil when given a local user auth hash
  for which no database match exists" do
    email = "newuser@southwest.edu"
    user = User.from_omniauth(
      {
        provider: "identity",
        uid:      email,
        info: {
          email: email
        }
      },
      institution: institutions(:southwest)
    )
    assert_nil user
  end

  test "from_omniauth() returns an existing user when given a local user auth
  hash for which a database match exists" do
    email       = "newuser@southwest.edu"
    institution = institutions(:southwest)
    Invitee.create!(email:       email,
                    purpose:     "hello world",
                    institution: institution)
    user = User.from_omniauth(
      {
        provider: "identity",
        uid:      email,
        info: {
          email: email
        }
      },
      institution: institution
    )
    assert_equal institution, user.institution
  end

  test "from_omniauth() returns a new user when given a SAML auth hash
  hash for which no database match exists" do
    institution = institutions(:southwest)
    user        = User.from_omniauth(SAML_AUTH_HASH,
                                     institution: institution)
    assert_equal "First Last", user.name
    assert_equal "OpenAthensUser@example.org", user.email
    assert_nil user.phone
    assert_equal institution, user.institution
  end

  test "from_omniauth() returns an existing user when given a SAML auth
  hash for which a database match exists" do
    institution = institutions(:southwest)
    email       = SAML_AUTH_HASH[:extra][:raw_info].
      attributes[institution.saml_email_attribute.to_sym].first
    @user.update!(email: email)

    user = User.from_omniauth(SAML_AUTH_HASH, institution: institution)
    assert_equal "First Last", user.name
    assert_equal "OpenAthensUser@example.org", user.email
    assert_nil user.phone
  end

  test "from_omniauth() populates the correct email from a SAML NameID" do
    institution = institutions(:southwest)
    institution.saml_email_location = Institution::SAMLEmailLocation::NAMEID
    auth        = SAML_AUTH_HASH.deep_dup
    auth[:uid]  = "CatDogFox@example.org"

    user = User.from_omniauth(auth, institution: institution)
    assert_equal "CatDogFox@example.org", user.email
  end

  test "from_omniauth() populates the correct email from a SAML attribute" do
    institution = institutions(:southwest)
    institution.saml_email_location = Institution::SAMLEmailLocation::ATTRIBUTE
    auth        = SAML_AUTH_HASH.deep_dup
    auth[:uid]  = "something else"

    user = User.from_omniauth(auth, institution: institution)
    assert_equal "OpenAthensUser@example.org", user.email
  end

  test "from_omniauth() returns a new user when given a Shibboleth auth
  hash for which no database match exists" do
    user = User.from_omniauth(SHIBBOLETH_AUTH_HASH,
                              institution: institutions(:southwest))
    assert_equal "Shib Boleth", user.name
    assert_equal "ShibbolethUser@example.org", user.email
    assert_equal "(888) 555-5555", user.phone
    assert_equal institutions(:southeast), user.institution
    assert_equal "Example Department", user.department.name
    assert_equal Affiliation.find_by_key(Affiliation::FACULTY_STAFF_KEY),
                 user.affiliation
  end

  test "from_omniauth() returns an existing user when given a Shibboleth auth
  hash for which a database match exists" do
    @user.update!(email: SHIBBOLETH_AUTH_HASH[:info][:email])

    user = User.from_omniauth(SHIBBOLETH_AUTH_HASH,
                              institution: institutions(:southeast))
    assert_equal @user, user
    assert_equal "Shib Boleth", user.name
    assert_equal "ShibbolethUser@example.org", user.email
    assert_equal "(888) 555-5555", user.phone
    # the institution shouldn't change
    assert_equal institutions(:southwest), user.institution
    assert_equal "Example Department", user.department.name
    assert_equal Affiliation.find_by_key(Affiliation::FACULTY_STAFF_KEY),
                 user.affiliation
  end

  test "from_omniauth() returns an updated user when given a Shibboleth
  developer auth hash" do
    assert_not_nil User.from_omniauth(
      {
        provider: "developer",
        info: {
          email: "user@example.org"
        }
      },
      institution: institutions(:southeast))
  end

  test "from_omniauth() with an unsupported provider raises an error" do
    assert_raises ArgumentError do
      User.from_omniauth({provider: "bogus"}, institution: @user.institution)
    end
  end

  # belongs_to_user_group?()

  test "belongs_to_user_group?() returns false for a user not associated with
  the group" do
    assert !@user.belongs_to_user_group?(user_groups(:sysadmin))
  end

  test "belongs_to_user_group?() returns true for a user directly associated
  with the group" do
    group              = user_groups(:sysadmin)
    @user.user_groups << group
    assert @user.belongs_to_user_group?(group)
  end

  test "belongs_to_user_group?() returns true for a user belonging to an AD
  group associated with the group" do
    skip # TODO: set up a mock AD group system for the test environment
    user       = users(:southeast_admin)
    user_group = user_groups(:sysadmin)
    assert user.belongs_to_user_group?(user_group)
  end

  # collection_admin?()

  test "collection_admin?() returns true when the user is a directly assigned
  administrator of the given collection" do
    collection = collections(:southeast_collection1)
    collection.administering_users << @user
    collection.save!
    assert @user.collection_admin?(collection)
  end

  test "collection_admin?() returns true when the user belongs to a user group
  that is allowed to administer the given unit" do
    group = user_groups(:southeast_unused)
    @user.user_groups << group
    collection = collections(:southeast_collection1)
    collection.administering_users << @user
    assert @user.collection_admin?(collection)
  end

  test "collection_admin?() returns false when the user is not an administrator
  of the given collection" do
    assert !@user.collection_admin?(collections(:southeast_collection1))
  end

  # collection_submitter?()

  test "collection_submitter?() returns true when the user is a directly
  assigned submitter in the given collection" do
    collection = collections(:southeast_collection1)
    collection.submitting_users << @user
    collection.save!
    assert @user.collection_submitter?(collection)
  end

  test "collection_submitter?() returns true when the user belongs to a user
  group that is allowed to submit to the given unit" do
    group = user_groups(:southeast_unused)
    @user.user_groups << group
    collection = collections(:southeast_collection1)
    collection.submitting_users << @user
    assert @user.collection_submitter?(collection)
  end

  test "collection_submitter?() returns false when the user is not a submitter
  in the given collection" do
    assert !@user.collection_submitter?(collections(:southeast_collection1))
  end

  # destroy()

  test "destroy() destroys the associated Identity" do
    identity = @user.identity
    @user.destroy!

    assert_raises ActiveRecord::RecordNotFound do
      identity.reload
    end
  end

  # effective_collection_admin?()

  test "effective_collection_admin?() returns true when the user is a
  sysadmin" do
    @user      = users(:southwest_sysadmin)
    collection = collections(:southeast_collection1)
    assert @user.effective_collection_admin?(collection)
  end

  test "effective_collection_admin?() returns true if the user is an
  administrator of the given collection's institution" do
    collection = collections(:southeast_collection1)
    @user.administering_institutions << collection.institution
    @user.save!
    assert @user.effective_collection_admin?(collection)
  end

  test "effective_collection_admin?() returns true when the user is an
  administrator of one of the collection's units" do
    collection = collections(:southeast_collection1)
    unit       = collection.primary_unit
    unit.administering_users << @user
    unit.save!
    assert @user.effective_collection_admin?(collection)
  end

  test "effective_collection_admin?() returns true when the user is an
  administrator of one of the given collection's parents" do
    parent = collections(:southeast_collection1)
    child  = collections(:southeast_collection1_collection1)
    parent.administering_users << @user
    parent.save!
    assert @user.effective_collection_admin?(child)
  end

  test "effective_collection_admin?() returns true when the user is an
  administrator of the given collection" do
    collection = collections(:southeast_collection1)
    collection.administering_users << @user
    collection.save!
    assert @user.effective_collection_admin?(collection)
  end

  test "effective_collection_admin?() returns false when the user is not an
  administrator of the given collection, nor a unit admin, nor a sysadmin" do
    assert !@user.effective_collection_admin?(collections(:southeast_collection1))
  end

  # effective_institution_admin?()

  test "effective_institution_admin?() returns true if the user is a sysadmin" do
    @user = users(:southwest_sysadmin)
    assert @user.effective_institution_admin?(@user.institution)
  end

  test "effective_institution_admin?() returns true if the user is an
  administrator of the given institution" do
    @user       = users(:southwest_sysadmin)
    institution = institutions(:southeast)
    @user.administering_institutions << institution
    @user.save!
    assert @user.effective_institution_admin?(institution)
  end

  test "effective_institution_admin?() returns false if the user is neither a
  member of the given institution nor a sysadmin" do
    assert !@user.effective_institution_admin?(institutions(:southwest))
  end

  # effective_submittable_collections()

  test "effective_submittable_collections() returns all collections in the same
  institution for sysadmins" do
    user = users(:southwest_sysadmin)
    assert_equal Collection.joins(:units).where("units.institution_id = ?",
                                                user.institution_id).count,
                 user.effective_submittable_collections.count
  end

  test "effective_submittable_collections() returns all unit collections for
  unit administrators" do
    user = users(:southeast_unit1_unit2_unit1_admin)
    assert_equal user.administering_units.count,
                 user.effective_submittable_collections.count
  end

  test "effective_submittable_collections() returns all administering
  collections for collection administrators" do
    user = users(:southeast_collection1_collection1_admin)
    assert_equal user.administering_collections.count,
                 user.effective_submittable_collections.count
  end

  test "effective_submittable_collections() returns all submitting collections
  for collection submitters" do
    user = users(:southeast_collection1_collection1_submitter)
    assert_equal user.submitting_collections.count,
                 user.effective_submittable_collections.count
  end

  test "effective_submittable_collections() returns an empty set for ordinary
  users" do
    assert_empty users(:southwest).effective_submittable_collections
  end

  # effective_collection_submitter?()

  test "effective_collection_submitter?() returns true when the user is a sysadmin" do
    @user      = users(:southwest_sysadmin)
    collection = collections(:southeast_collection1)
    assert @user.effective_collection_submitter?(collection)
  end

  test "effective_collection_submitter?() returns true when the user is an
  administrator of one of the collection's units" do
    collection = collections(:southeast_collection1)
    unit       = collection.primary_unit
    unit.administering_users << @user
    unit.save!
    assert @user.effective_collection_submitter?(collection)
  end

  test "effective_collection_submitter?() returns true when the user is an
  administrator of one of the given collection's parents" do
    parent = collections(:southeast_collection1)
    child  = collections(:southeast_collection1_collection1)
    parent.administering_users << @user
    parent.save!
    assert @user.effective_collection_submitter?(child)
  end

  test "effective_collection_submitter?() returns true when the user is an
  administrator of the given collection" do
    collection = collections(:southeast_collection1)
    collection.administering_users << @user
    collection.save!
    assert @user.effective_collection_submitter?(collection)
  end

  test "effective_collection_submitter?() returns true when the user is a
  submitter in the given collection" do
    collection = collections(:southeast_collection1)
    collection.submitting_users << @user
    collection.save!
    assert @user.effective_collection_submitter?(collection)
  end

  test "effective_collection_submitter?() returns false when the user is not an
  administrator of the given collection, nor a unit admin, nor a sysadmin" do
    assert !@user.effective_collection_submitter?(collections(:southeast_collection1))
  end

  # effective_unit_admin?()

  test "effective_unit_admin?() returns true when the user is a sysadmin" do
    @user = users(:southwest_sysadmin)
    unit  = units(:southeast_unit1)
    assert @user.effective_unit_admin?(unit)
  end

  test "effective_unit_admin?() returns true when the user is an administrator
  of the given unit's institution" do
    unit = units(:southeast_unit1)
    @user.administering_institutions << unit.institution
    @user.save!
    assert @user.effective_unit_admin?(unit)
  end

  test "effective_unit_admin?() returns true when the user is an administrator
  of the given unit's parent" do
    parent = units(:southeast_unit1)
    child  = units(:southeast_unit1_unit1)
    parent.administering_users << @user
    parent.save!
    assert @user.effective_unit_admin?(child)
  end

  test "effective_unit_admin?() returns true when the user is an administrator
  of the given unit" do
    unit = units(:southeast_unit1)
    unit.administering_users << @user
    unit.save!
    assert @user.effective_unit_admin?(unit)
  end

  test "effective_unit_admin?() returns false when the user is not an
  administrator of the given unit" do
    assert !@user.effective_unit_admin?(units(:southeast_unit1))
  end

  # email

  test "email is required" do
    @user.email = nil
    assert !@user.valid?
    @user.email = "test@example.org"
    assert @user.valid?
  end

  test "email must be unique" do
    email = @user.email
    assert_raises ActiveRecord::RecordInvalid do
      User.create!(email: email,
                   name:  email)
    end
  end

  # institution_admin?()

  test "institution_admin?() returns true if the user is an administrator of
  the given institution" do
    institution = institutions(:southwest)
    @user.administering_institutions << institution
    @user.save!
    assert @user.institution_admin?(institution)
  end

  test "institution_admin?() returns false if the user is not a member of the
  given institution" do
    assert !@user.institution_admin?(institutions(:southwest))
  end

  test "institution_admin?() returns false for a nil argument" do
    assert !@user.institution_admin?(nil)
  end

  # name

  test "name is required" do
    @user.name = nil
    assert !@user.valid?
    @user.name = "test"
    assert @user.valid?
  end

  # netid()

  test "netid() returns the NetID" do
    assert_equal @user.email.split("@").first, @user.netid
  end

  # save()

  test "save() updates the email of the associated LocalIdentity" do
    new_email = "new@example.edu"
    @user.update!(email: new_email)
    assert_equal new_email, @user.identity.email
  end

  # sysadmin?()

  test "sysadmin?() returns true when the user is directly associated with the
  sysadmin user group" do
    @user = users(:southwest_sysadmin)
    assert @user.sysadmin?
  end

  test "sysadmin?() returns true when the user is a member of an AD group
  included in the sysadmin user group" do
    @user = users(:southeast_sysadmin)
    @user.user_groups.destroy_all
    assert @user.sysadmin?
  end

  test "sysadmin?() returns false when the user is not a member of the sysadmin
  user group in any way" do
    assert !@user.sysadmin?
  end

  # to_autocomplete()

  test "to_autocomplete() returns the name and email when both are present" do
    assert_equal "#{@user.name} (#{@user.email})",
                 @user.to_autocomplete
    @user.name = nil
    assert_equal @user.email, @user.to_autocomplete
  end

  # unit_admin?()

  test "unit_admin?() returns true when the user is a directly assigned
  administrator of the given unit" do
    unit = units(:southeast_unit1)
    unit.administering_users << @user
    unit.save!
    assert @user.unit_admin?(unit)
  end

  test "unit_admin?() returns true when the user belongs to a user group that
  is allowed to administer the given unit" do
    group = user_groups(:southeast_unused)
    @user.user_groups << group
    unit = units(:southeast_unit1)
    unit.administering_groups << group
    assert @user.unit_admin?(unit)
  end

  test "unit_admin?() returns false when the user is not an administrator of
  the given unit" do
    assert !@user.unit_admin?(units(:southeast_unit1))
  end

end
