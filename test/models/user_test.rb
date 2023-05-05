require 'test_helper'

class UserTest < ActiveSupport::TestCase

  setup do
    @user = users(:example)
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

  test "from_omniauth() returns a LocalUser" do
    email = "newuser@southwest.edu"
    Invitee.create!(email:       email,
                    note:        "hello world",
                    institution: institutions(:southwest))
    user = User.from_omniauth(provider: "identity",
                              info:     { email: email })
    assert_kind_of LocalUser, user
  end

  test "from_omniauth() returns a ShibbolethUser" do
    user = User.from_omniauth(provider: "shibboleth",
                              info:     { email: "user@example.org" })
    assert_kind_of ShibbolethUser, user

    user = User.from_omniauth(provider: "developer",
                              info:     { email: "user@example.org" })
    assert_kind_of ShibbolethUser, user
  end

  test "from_omniauth() returns a SamlUser" do
    user = User.from_omniauth(provider: "saml",
                              extra: {
                                raw_info: OneLogin::RubySaml::Attributes.new(emailAddress: "user@example.org")
                              })
    assert_kind_of SamlUser, user
  end

  test "from_omniauth() with an unsupported provider raises an error" do
    assert_raises ArgumentError do
      User.from_omniauth(provider: "bogus")
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
    skip # this is not testable because AD group membership checks don't happen in the test environment
    # TODO: set up a mock AD group system for the test environment?
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
      LocalUser.create!(email: email, name: email)
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

  test "submitter?() returns false when the user is not a submitter in the given collection" do
    assert !@user.submitter?(collections(:uiuc_collection1))
  end

  # sysadmin?()

  test "sysadmin?() raises an error" do
    assert_raises do
      @user.becomes(User).sysadmin?
    end
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
