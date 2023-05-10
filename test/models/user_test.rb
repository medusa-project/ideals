require 'test_helper'

class UserTest < ActiveSupport::TestCase

  setup do
    @user = users(:example)
  end

  OPENATHENS_AUTH_HASH = {
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
      raw_info: OneLogin::RubySaml::Attributes.new(
        "urn:oid:1.3.6.1.4.1.5923.1.1.1.9": [
          "member@southwest.edu"
        ],
        emailAddress: [
          "OpenAthensUser@example.org"
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
    assert_equal User::AuthMethod::LOCAL, user.auth_method
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

  # fetch_from_omniauth_openathens()

  test "fetch_from_omniauth_openathens() with a matching email returns the user" do
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
    assert_equal user, User.fetch_from_omniauth_openathens(auth)
  end

  test "fetch_from_omniauth_openathens() with a non-matching email returns nil" do
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
    assert_nil User.fetch_from_omniauth_openathens(auth)
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
                    note:        "hello world",
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
    assert user.local?
    assert_equal institution, user.institution
  end

  test "from_omniauth() returns a new user when given an OpenAthens auth hash
  hash for which no database match exists" do
    institution = institutions(:southwest)
    user        = User.from_omniauth(OPENATHENS_AUTH_HASH,
                                     institution: institution)
    assert user.openathens?
    assert_equal "OpenAthensUser@example.org", user.name
    assert_equal "OpenAthensUser@example.org", user.email
    assert_nil user.phone
    assert_equal institution, user.institution
  end

  test "from_omniauth() returns an existing user when given an OpenAthens auth
  hash for which a database match exists" do
    institution = institutions(:southwest)
    email       = OPENATHENS_AUTH_HASH[:extra][:raw_info].
      attributes[institution.saml_email_attribute.to_sym].first
    @user.update!(email: email)

    user = User.from_omniauth(OPENATHENS_AUTH_HASH, institution: institution)
    assert user.openathens?
    assert_equal "OpenAthensUser@example.org", user.name
    assert_equal "OpenAthensUser@example.org", user.email
    assert_nil user.phone
    assert_equal institution, user.institution
  end

  test "from_omniauth() returns a new user when given a Shibboleth auth
  hash for which no database match exists" do
    user = User.from_omniauth(SHIBBOLETH_AUTH_HASH,
                              institution: institutions(:southwest))
    assert user.shibboleth?
    assert_equal "Shib Boleth", user.name
    assert_equal "ShibbolethUser@example.org", user.email
    assert_equal "(888) 555-5555", user.phone
    assert_equal institutions(:uiuc), user.institution
    assert_equal "Example Department", user.department.name
    assert_equal Affiliation.find_by_key(Affiliation::FACULTY_STAFF_KEY),
                 user.affiliation
  end

  test "from_omniauth() returns an existing user when given a Shibboleth auth
  hash for which a database match exists" do
    @user.update!(email: SHIBBOLETH_AUTH_HASH[:info][:email])

    user = User.from_omniauth(SHIBBOLETH_AUTH_HASH,
                              institution: institutions(:uiuc))
    assert_equal @user, user
    assert user.shibboleth?
    assert_equal "Shib Boleth", user.name
    assert_equal "ShibbolethUser@example.org", user.email
    assert_equal "(888) 555-5555", user.phone
    assert_equal institutions(:uiuc), user.institution
    assert_equal "Example Department", user.department.name
    assert_equal Affiliation.find_by_key(Affiliation::FACULTY_STAFF_KEY),
                 user.affiliation
  end

  test "from_omniauth() returns an updated user when given a Shibboleth
  developer auth hash" do
    user = User.from_omniauth(
      {
        provider: "developer",
        info: {
          email: "user@example.org"
        }
      },
      institution: institutions(:uiuc))
    assert user.shibboleth?
  end

  test "from_omniauth() with an unsupported provider raises an error" do
    assert_raises ArgumentError do
      User.from_omniauth(provider: "bogus")
    end
  end

  # auth_method

  test "auth_method must be set to one of the AuthMethod constant values" do
    @user.auth_method = User::AuthMethod::OPENATHENS
    assert @user.valid?
    @user.auth_method = 99
    assert !@user.valid?
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
    user       = users(:uiuc_admin)
    user_group = user_groups(:sysadmin)
    assert user.belongs_to_user_group?(user_group)
  end

  # collection_admin?()

  test "collection_admin?() returns true when the user is a directly assigned
  administrator of the given collection" do
    collection = collections(:uiuc_collection1)
    collection.administering_users << @user
    collection.save!
    assert @user.collection_admin?(collection)
  end

  test "collection_admin?() returns true when the user belongs to a user group
  that is allowed to administer the given unit" do
    group = user_groups(:uiuc_unused)
    @user.user_groups << group
    collection = collections(:uiuc_collection1)
    collection.administering_users << @user
    assert @user.collection_admin?(collection)
  end

  test "collection_admin?() returns false when the user is not an administrator
  of the given collection" do
    assert !@user.collection_admin?(collections(:uiuc_collection1))
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
    @user      = users(:example_sysadmin)
    collection = collections(:uiuc_collection1)
    assert @user.effective_collection_admin?(collection)
  end

  test "effective_collection_admin?() returns true if the user is an
  administrator of the given collection's institution" do
    collection = collections(:uiuc_collection1)
    @user.administering_institutions << collection.institution
    @user.save!
    assert @user.effective_collection_admin?(collection)
  end

  test "effective_collection_admin?() returns true when the user is an
  administrator of one of the collection's units" do
    collection = collections(:uiuc_collection1)
    unit       = collection.primary_unit
    unit.administering_users << @user
    unit.save!
    assert @user.effective_collection_admin?(collection)
  end

  test "effective_collection_admin?() returns true when the user is an
  administrator of one of the given collection's parents" do
    parent = collections(:uiuc_collection1)
    child  = collections(:uiuc_collection1_collection1)
    parent.administering_users << @user
    parent.save!
    assert @user.effective_collection_admin?(child)
  end

  test "effective_collection_admin?() returns true when the user is an
  administrator of the given collection" do
    collection = collections(:uiuc_collection1)
    collection.administering_users << @user
    collection.save!
    assert @user.effective_collection_admin?(collection)
  end

  test "effective_collection_admin?() returns false when the user is not an
  administrator of the given collection, nor a unit admin, nor a sysadmin" do
    assert !@user.effective_collection_admin?(collections(:uiuc_collection1))
  end

  # effective_institution_admin?()

  test "effective_institution_admin?() returns true if the user is a sysadmin" do
    @user = users(:example_sysadmin)
    assert @user.effective_institution_admin?(@user.institution)
  end

  test "effective_institution_admin?() returns true if the user is an
  administrator of the given institution" do
    @user   = users(:example_sysadmin)
    institution = institutions(:uiuc)
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
    user = users(:example_sysadmin)
    assert_equal Collection.joins(:units).where("units.institution_id = ?",
                                                user.institution_id).count,
                 user.effective_submittable_collections.count
  end

  test "effective_submittable_collections() returns all unit collections for
  unit administrators" do
    user = users(:uiuc_unit1_unit2_unit1_admin)
    assert_equal user.administering_units.count,
                 user.effective_submittable_collections.count
  end

  test "effective_submittable_collections() returns all administering
  collections for collection administrators" do
    user = users(:uiuc_collection1_collection1_admin)
    assert_equal user.administering_collections.count,
                 user.effective_submittable_collections.count
  end

  test "effective_submittable_collections() returns all submitting collections
  for collection submitters" do
    user = users(:uiuc_collection1_collection1_submitter)
    assert_equal user.submitting_collections.count,
                 user.effective_submittable_collections.count
  end

  test "effective_submittable_collections() returns an empty set for ordinary
  users" do
    assert_empty users(:example).effective_submittable_collections
  end

  # effective_submitter?()

  test "effective_submitter?() returns true when the user is a sysadmin" do
    @user = users(:example_sysadmin)
    collection = collections(:uiuc_collection1)
    assert @user.effective_submitter?(collection)
  end

  test "effective_submitter?() returns true when the user is an administrator of
  one of the collection's units" do
    collection = collections(:uiuc_collection1)
    unit = collection.primary_unit
    unit.administering_users << @user
    unit.save!
    assert @user.effective_submitter?(collection)
  end

  test "effective_submitter?() returns true when the user is an administrator
  of one of the given collection's parents" do
    parent = collections(:uiuc_collection1)
    child  = collections(:uiuc_collection1_collection1)
    parent.administering_users << @user
    parent.save!
    assert @user.effective_submitter?(child)
  end

  test "effective_submitter?() returns true when the user is an administrator
  of the given collection" do
    collection = collections(:uiuc_collection1)
    collection.administering_users << @user
    collection.save!
    assert @user.effective_submitter?(collection)
  end

  test "effective_submitter?() returns true when the user is a submitter in the
  given collection" do
    collection = collections(:uiuc_collection1)
    collection.submitting_users << @user
    collection.save!
    assert @user.effective_submitter?(collection)
  end

  test "effective_submitter?() returns false when the user is not an
  administrator of the given collection, nor a unit admin, nor a sysadmin" do
    assert !@user.effective_submitter?(collections(:uiuc_collection1))
  end

  # effective_unit_admin?()

  test "effective_unit_admin?() returns true when the user is a sysadmin" do
    @user = users(:example_sysadmin)
    unit      = units(:uiuc_unit1)
    assert @user.effective_unit_admin?(unit)
  end

  test "effective_unit_admin?() returns true when the user is an administrator
  of the given unit's institution" do
    unit = units(:uiuc_unit1)
    @user.administering_institutions << unit.institution
    @user.save!
    assert @user.effective_unit_admin?(unit)
  end

  test "effective_unit_admin?() returns true when the user is an administrator
  of the given unit's parent" do
    parent = units(:uiuc_unit1)
    child  = units(:uiuc_unit1_unit1)
    parent.administering_users << @user
    parent.save!
    assert @user.effective_unit_admin?(child)
  end

  test "effective_unit_admin?() returns true when the user is an administrator
  of the given unit" do
    unit = units(:uiuc_unit1)
    unit.administering_users << @user
    unit.save!
    assert @user.effective_unit_admin?(unit)
  end

  test "effective_unit_admin?() returns false when the user is not an
  administrator of the given unit" do
    assert !@user.effective_unit_admin?(units(:uiuc_unit1))
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
      User.create!(email:       email,
                   name:        email,
                   auth_method: User::AuthMethod::LOCAL)
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

  # local?()

  test "local?() returns false for non-local users" do
    @user.auth_method = User::AuthMethod::OPENATHENS
    assert !@user.local?
  end

  test "local?() returns true for local users" do
    @user.auth_method = User::AuthMethod::LOCAL
    assert @user.local?
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

  # openathens?()

  test "openathens?() returns false for non-OpenAthens users" do
    @user.auth_method = User::AuthMethod::LOCAL
    assert !@user.openathens?
  end

  test "openathens?() returns true for OpenAthens users" do
    @user.auth_method = User::AuthMethod::OPENATHENS
    assert @user.openathens?
  end

  # save()

  test "save() updates the email of the associated LocalIdentity" do
    new_email = "new@example.edu"
    @user.update!(email: new_email)
    assert_equal new_email, @user.identity.email
  end

  # shibboleth?()

  test "shibboleth?() returns false for non-Shibboleth users" do
    @user.auth_method = User::AuthMethod::LOCAL
    assert !@user.shibboleth?
  end

  test "shibboleth?() returns true for Shibboleth users" do
    @user.auth_method = User::AuthMethod::SHIBBOLETH
    assert @user.shibboleth?
  end

  # submitter?()

  test "submitter?() returns true when the user is a directly assigned
  submitter in the given collection" do
    collection = collections(:uiuc_collection1)
    collection.submitting_users << @user
    collection.save!
    assert @user.submitter?(collection)
  end

  test "submitter?() returns true when the user belongs to a user group that
  is allowed to submit to the given unit" do
    group = user_groups(:uiuc_unused)
    @user.user_groups << group
    collection = collections(:uiuc_collection1)
    collection.submitting_users << @user
    assert @user.submitter?(collection)
  end

  test "submitter?() returns false when the user is not a submitter in the
  given collection" do
    assert !@user.submitter?(collections(:uiuc_collection1))
  end

  # sysadmin?()

  test "sysadmin?() with the local auth method returns true when the user
  is directly associated with the sysadmin user group" do
    @user = users(:example_sysadmin)
    assert @user.sysadmin?
  end

  test "sysadmin?() with the local auth method returns false when the user is
  not directly associated with the sysadmin user group" do
    assert !@user.sysadmin?
  end

  test "sysadmin?() with the OpenAthens auth method returns true when the user
  is directly associated with the sysadmin user group" do
    @user.auth_method = User::AuthMethod::OPENATHENS
    user_groups(:sysadmin).users << @user
    assert @user.sysadmin?
  end

  test "sysadmin?() with the OpenAthens auth method returns false when the user
  is not directly associated with the sysadmin user group" do
    @user.auth_method = User::AuthMethod::OPENATHENS
    assert !@user.sysadmin?
  end

  test "sysadmin?() with the Shibboleth auth method returns true when the user
  is directly associated with the sysadmin user group" do
    @user.auth_method = User::AuthMethod::SHIBBOLETH
    user_groups(:sysadmin).users << @user
    assert @user.sysadmin?
  end

  test "sysadmin?() with the Shibboleth auth method returns false when the user
  is not directly associated with the sysadmin user group" do
    @user.auth_method = User::AuthMethod::SHIBBOLETH
    assert !@user.sysadmin?
  end

  test "sysadmin?() with the Shibboleth auth method returns true when the user
  is a member of an LDAP group included in the sysadmin user group" do
    @user = users(:example_sysadmin)
    @user.auth_method = User::AuthMethod::SHIBBOLETH
    assert @user.sysadmin?
  end

  test "sysadmin?() with the Shibboleth auth method returns false when the user
  is not a member of the sysadmin LDAP group" do
    @user.auth_method = User::AuthMethod::SHIBBOLETH
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
    unit = units(:uiuc_unit1)
    unit.administering_users << @user
    unit.save!
    assert @user.unit_admin?(unit)
  end

  test "unit_admin?() returns true when the user belongs to a user group that
  is allowed to administer the given unit" do
    group = user_groups(:uiuc_unused)
    @user.user_groups << group
    unit = units(:uiuc_unit1)
    unit.administering_groups << group
    assert @user.unit_admin?(unit)
  end

  test "unit_admin?() returns false when the user is not an administrator of
  the given unit" do
    assert !@user.unit_admin?(units(:uiuc_unit1))
  end

end
