require 'test_helper'

class UserTest < ActiveSupport::TestCase

  setup do
    @user = users(:norights)
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

  # effective_institution_admin?()

  test "effective_institution_admin?() returns true if the user is a sysadmin" do
    @user = users(:local_sysadmin)
    assert @user.effective_institution_admin?(@user.institution)
  end

  test "effective_institution_admin?() returns true if the user is an
  administrator of the given institution" do
    @user   = users(:local_sysadmin)
    institution = institutions(:uiuc)
    @user.administering_institutions << institution
    @user.save!
    assert @user.effective_institution_admin?(institution)
  end

  test "effective_institution_admin?() returns false if the user is neither a
  member of the given institution nor a sysadmin" do
    assert !@user.effective_institution_admin?(institutions(:southwest))
  end

  # effective_manager?()

  test "effective_manager?() returns true when the user is a sysadmin" do
    @user = users(:local_sysadmin)
    collection = collections(:collection1)
    assert @user.effective_manager?(collection)
  end

  test "effective_manager?() returns true if the user is an administrator of
  the given collection's institution" do
    collection = collections(:collection1)
    @user.administering_institutions << collection.institution
    @user.save!
    assert @user.effective_manager?(collection)
  end

  test "effective_manager?() returns true when the user is an administrator of
  one of the collection's units" do
    collection = collections(:collection1)
    unit = collection.primary_unit
    unit.administering_users << @user
    unit.save!
    assert @user.effective_manager?(collection)
  end

  test "effective_manager?() returns true when the user is a manager of one of
  the given collection's parents" do
    parent = collections(:collection1)
    child  = collections(:collection1_collection1)
    parent.managing_users << @user
    parent.save!
    assert @user.effective_manager?(child)
  end

  test "effective_manager?() returns true when the user is a manager of the
  given collection" do
    collection = collections(:collection1)
    collection.managing_users << @user
    collection.save!
    assert @user.effective_manager?(collection)
  end

  test "effective_manager?() returns false when the user is not a manager of
  the given collection, nor a unit admin, nor a sysadmin" do
    assert !@user.effective_manager?(collections(:collection1))
  end

  # effective_submitter?()

  test "effective_submitter?() returns true when the user is a sysadmin" do
    @user = users(:local_sysadmin)
    collection = collections(:collection1)
    assert @user.effective_submitter?(collection)
  end

  test "effective_submitter?() returns true when the user is an administrator of
  one of the collection's units" do
    collection = collections(:collection1)
    unit = collection.primary_unit
    unit.administering_users << @user
    unit.save!
    assert @user.effective_submitter?(collection)
  end

  test "effective_submitter?() returns true when the user is a manager of one
  of the given collection's parents" do
    parent = collections(:collection1)
    child  = collections(:collection1_collection1)
    parent.managing_users << @user
    parent.save!
    assert @user.effective_submitter?(child)
  end

  test "effective_submitter?() returns true when the user is a manager of the
  given collection" do
    collection = collections(:collection1)
    collection.managing_users << @user
    collection.save!
    assert @user.effective_submitter?(collection)
  end

  test "effective_submitter?() returns true when the user is a submitter in the
  given collection" do
    collection = collections(:collection1)
    collection.submitting_users << @user
    collection.save!
    assert @user.effective_submitter?(collection)
  end

  test "effective_submitter?() returns false when the user is not a manager of
  the given collection, nor a unit admin, nor a sysadmin" do
    assert !@user.effective_submitter?(collections(:collection1))
  end

  # effective_submittable_collections()

  test "effective_submittable_collections() returns all collections for
  sysadmins" do
    assert_equal Collection.count,
                 users(:local_sysadmin).effective_submittable_collections.count
  end

  test "effective_submittable_collections() returns all unit collections for
  unit administrators" do
    user = users(:unit1_unit2_unit1_admin)
    assert_equal user.administering_units.count,
                 user.effective_submittable_collections.count
  end

  test "effective_submittable_collections() returns all managing collections for
  collection managers" do
    user = users(:collection1_collection1_manager)
    assert_equal user.managing_collections.count,
                 user.effective_submittable_collections.count
  end

  test "effective_submittable_collections() returns all submitting collections
  for collection submitters" do
    user = users(:collection1_collection1_submitter)
    assert_equal user.submitting_collections.count,
                 user.effective_submittable_collections.count
  end

  test "effective_submittable_collections() returns an empty set for ordinary
  users" do
    assert_empty users(:norights).effective_submittable_collections
  end

  # effective_unit_admin?()

  test "effective_unit_admin?() returns true when the user is a sysadmin" do
    @user = users(:local_sysadmin)
    unit      = units(:unit1)
    assert @user.effective_unit_admin?(unit)
  end

  test "effective_unit_admin?() returns true when the user is an administrator
  of the given unit's institution" do
    unit = units(:unit1)
    @user.administering_institutions << unit.institution
    @user.save!
    assert @user.effective_unit_admin?(unit)
  end

  test "effective_unit_admin?() returns true when the user is an administrator
  of the given unit's parent" do
    parent = units(:unit1)
    child  = units(:unit1_unit1)
    parent.administering_users << @user
    parent.save!
    assert @user.effective_unit_admin?(child)
  end

  test "effective_unit_admin?() returns true when the user is an administrator
  of the given unit" do
    unit = units(:unit1)
    unit.administering_users << @user
    unit.save!
    assert @user.effective_unit_admin?(unit)
  end

  test "effective_unit_admin?() returns false when the user is not an
  administrator of the given unit" do
    assert !@user.effective_unit_admin?(units(:unit1))
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
      LocalUser.create!(email: email, name: email, uid: email)
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

  # manager?()

  test "manager?() returns true when the user is a directly assigned manager of
  the given collection" do
    collection = collections(:collection1)
    collection.managing_users << @user
    collection.save!
    assert @user.manager?(collection)
  end

  test "manager?() returns true when the user belongs to a user group that
  is allowed to manage the given unit" do
    group = user_groups(:temp)
    @user.user_groups << group
    collection = collections(:collection1)
    collection.managing_users << @user
    assert @user.manager?(collection)
  end

  test "manager?() returns false when the user is not a manager of the given collection" do
    assert !@user.manager?(collections(:collection1))
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
    collection = collections(:collection1)
    collection.submitting_users << @user
    collection.save!
    assert @user.submitter?(collection)
  end

  test "submitter?() returns true when the user belongs to a user group that
  is allowed to submit to the given unit" do
    group = user_groups(:temp)
    @user.user_groups << group
    collection = collections(:collection1)
    collection.submitting_users << @user
    assert @user.submitter?(collection)
  end

  test "submitter?() returns false when the user is not a submitter in the given collection" do
    assert !@user.submitter?(collections(:collection1))
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

  # uid

  test "uid is required" do
    @user.uid = nil
    assert !@user.valid?
    @user.uid = "test"
    assert @user.valid?
  end

  test "uid must be unique" do
    uid = @user.uid
    assert_raises ActiveRecord::RecordInvalid do
      LocalUser.create!(email: "random12345@example.org",
                        name: uid,
                        uid: uid)
    end
  end

  # unit_admin?()

  test "unit_admin?() returns true when the user is a directly assigned
  administrator of the given unit" do
    unit = units(:unit1)
    unit.administering_users << @user
    unit.save!
    assert @user.unit_admin?(unit)
  end

  test "unit_admin?() returns true when the user belongs to a user group that
  is allowed to administer the given unit" do
    group = user_groups(:temp)
    @user.user_groups << group
    unit = units(:unit1)
    unit.administering_groups << group
    assert @user.unit_admin?(unit)
  end

  test "unit_admin?() returns false when the user is not an administrator of
  the given unit" do
    assert !@user.unit_admin?(units(:unit1))
  end

end
