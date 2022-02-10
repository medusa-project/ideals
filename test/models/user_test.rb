require 'test_helper'

class UserTest < ActiveSupport::TestCase

  setup do
    @instance = users(:norights)
  end

  # from_autocomplete_string()

  test "from_autocomplete_string() returns a user" do
    string = @instance.to_autocomplete
    actual = User.from_autocomplete_string(string)
    assert_equal @instance, actual
  end

  test "from_autocomplete_string() returns nil for no match" do
    string = "Bogus Bogus (bogus.example.org)"
    assert_nil User.from_autocomplete_string(string)
  end

  # any_institution_admin?()

  test "any_institution_admin?() returns true if the user is an institution
  admin" do
    institution = institutions(:uiuc)
    @instance.org_dn = institution.org_dn
    assert @instance.any_institution_admin?
  end

  test "any_institution_admin?() returns false if the user is not an institution
  admin" do
    assert !@instance.any_institution_admin?
  end

  # belongs_to?()

  test "belongs_to?() returns false for a user not associated with the group" do
    assert !@instance.belongs_to?(user_groups(:sysadmin))
  end

  test "belongs_to?() returns true for a user directly associated with the
  group" do
    group                  = user_groups(:sysadmin)
    @instance.user_groups << group
    assert @instance.belongs_to?(group)
  end

  test "belongs_to?() returns true for a user belonging to an LDAP group
  associated with the group" do
    user            = users(:uiuc)
    user_group      = user_groups(:sysadmin)
    ad_group        = user_group.ad_groups.first
    ad_group.users << user
    assert user.belongs_to?(user_group)
  end

  # effective_institution_admin?()

  test "effective_institution_admin?() returns true if the user is a sysadmin" do
    @instance = users(:local_sysadmin)
    assert @instance.effective_institution_admin?(@instance.institution)
  end

  # TODO: this test will go away when we have an institution-admin AD group
  test "effective_institution_admin?() returns true if the user is a member of
  the given institution" do
    @instance = users(:uiuc)
    assert @instance.effective_institution_admin?(@instance.institution)
  end

  test "effective_institution_admin?() returns false if the user is not a
  member of the given institution" do
    assert !@instance.effective_institution_admin?(institutions(:somewhere))
  end

  # effective_manager?()

  test "effective_manager?() returns true when the user is a sysadmin" do
    @instance = users(:local_sysadmin)
    collection = collections(:collection1)
    assert @instance.effective_manager?(collection)
  end

  test "effective_manager?() returns true when the user is an administrator of
  one of the collection's units" do
    collection = collections(:collection1)
    unit = collection.primary_unit
    unit.administering_users << @instance
    unit.save!
    assert @instance.effective_manager?(collection)
  end

  test "effective_manager?() returns true when the user is a manager of one of
  the given collection's parents" do
    parent = collections(:collection1)
    child  = collections(:collection1_collection1)
    parent.managing_users << @instance
    parent.save!
    assert @instance.effective_manager?(child)
  end

  test "effective_manager?() returns true when the user is a manager of the
  given collection" do
    collection = collections(:collection1)
    collection.managing_users << @instance
    collection.save!
    assert @instance.effective_manager?(collection)
  end

  test "effective_manager?() returns false when the user is not a manager of
  the given collection, nor a unit admin, nor a sysadmin" do
    assert !@instance.effective_manager?(collections(:collection1))
  end

  # effective_submitter?()

  test "effective_submitter?() returns true when the user is a sysadmin" do
    @instance = users(:local_sysadmin)
    collection = collections(:collection1)
    assert @instance.effective_submitter?(collection)
  end

  test "effective_submitter?() returns true when the user is an administrator of
  one of the collection's units" do
    collection = collections(:collection1)
    unit = collection.primary_unit
    unit.administering_users << @instance
    unit.save!
    assert @instance.effective_submitter?(collection)
  end

  test "effective_submitter?() returns true when the user is a manager of one
  of the given collection's parents" do
    parent = collections(:collection1)
    child  = collections(:collection1_collection1)
    parent.managing_users << @instance
    parent.save!
    assert @instance.effective_submitter?(child)
  end

  test "effective_submitter?() returns true when the user is a manager of the
  given collection" do
    collection = collections(:collection1)
    collection.managing_users << @instance
    collection.save!
    assert @instance.effective_submitter?(collection)
  end

  test "effective_submitter?() returns true when the user is a submitter in the
  given collection" do
    collection = collections(:collection1)
    collection.submitting_users << @instance
    collection.save!
    assert @instance.effective_submitter?(collection)
  end

  test "effective_submitter?() returns false when the user is not a manager of
  the given collection, nor a unit admin, nor a sysadmin" do
    assert !@instance.effective_submitter?(collections(:collection1))
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
    @instance = users(:local_sysadmin)
    unit      = units(:unit1)
    assert @instance.effective_unit_admin?(unit)
  end

  test "effective_unit_admin?() returns true when the user is an administrator
  of the given unit's parent" do
    parent = units(:unit1)
    child  = units(:unit1_unit1)
    parent.administering_users << @instance
    parent.save!
    assert @instance.effective_unit_admin?(child)
  end

  test "effective_unit_admin?() returns true when the user is an administrator
  of the given unit" do
    unit = units(:unit1)
    unit.administering_users << @instance
    unit.save!
    assert @instance.effective_unit_admin?(unit)
  end

  test "effective_unit_admin?() returns false when the user is not an
  administrator of the given unit" do
    assert !@instance.effective_unit_admin?(units(:unit1))
  end

  # email

  test "email is required" do
    @instance.email = nil
    assert !@instance.valid?
    @instance.email = "test@example.org"
    assert @instance.valid?
  end

  test "email must be unique" do
    email = @instance.email
    assert_raises ActiveRecord::RecordInvalid do
      LocalUser.create!(email: email, name: email, uid: email)
    end
  end

  # institution()

  test "institution() returns the institution with matching org DN" do
    @instance = users(:uiuc)
    assert_equal institutions(:uiuc), @instance.institution
  end

  test "institution() returns nil when there is no institution with matching org DN" do
    @instance.org_dn = "bogus"
    assert_nil @instance.institution
  end

  test "institution() returns nil when the instance does not have an org DN" do
    @instance.org_dn = nil
    assert_nil @instance.institution
  end

  # institution_admin?()

  # TODO: this test will go away when we have an institution-admin AD group
  test "institution_admin?() returns true if the user is a member of the given
  institution" do
    @instance = users(:uiuc)
    assert @instance.institution_admin?(@instance.institution)
  end

  test "institution_admin?() returns false if the user is not a member of the
  given institution" do
    assert !@instance.institution_admin?(institutions(:somewhere))
  end

  test "institution_admin?() returns false for a nil argument" do
    assert !@instance.institution_admin?(nil)
  end

  # manager?()

  test "manager?() returns true when the user is a directly assigned manager of
  the given collection" do
    collection = collections(:collection1)
    collection.managing_users << @instance
    collection.save!
    assert @instance.manager?(collection)
  end

  test "manager?() returns true when the user belongs to a user group that
  is allowed to manage the given unit" do
    group = user_groups(:temp)
    @instance.user_groups << group
    collection = collections(:collection1)
    collection.managing_users << @instance
    assert @instance.manager?(collection)
  end

  test "manager?() returns false when the user is not a manager of the given collection" do
    assert !@instance.manager?(collections(:collection1))
  end

  # name

  test "name is required" do
    @instance.name = nil
    assert !@instance.valid?
    @instance.name = "test"
    assert @instance.valid?
  end

  # submitter?()

  test "submitter?() returns true when the user is a directly assigned
  submitter in the given collection" do
    collection = collections(:collection1)
    collection.submitting_users << @instance
    collection.save!
    assert @instance.submitter?(collection)
  end

  test "submitter?() returns true when the user belongs to a user group that
  is allowed to submit to the given unit" do
    group = user_groups(:temp)
    @instance.user_groups << group
    collection = collections(:collection1)
    collection.submitting_users << @instance
    assert @instance.submitter?(collection)
  end

  test "submitter?() returns false when the user is not a submitter in the given collection" do
    assert !@instance.submitter?(collections(:collection1))
  end

  # sysadmin?()

  test "sysadmin?() raises an error" do
    assert_raises do
      @instance.becomes(User).sysadmin?
    end
  end

  # to_autocomplete()

  test "to_autocomplete() returns the name and email when both are present" do
    assert_equal "#{@instance.name} (#{@instance.email})",
                 @instance.to_autocomplete
    @instance.name = nil
    assert_equal @instance.email, @instance.to_autocomplete
  end

  # uid

  test "uid is required" do
    @instance.uid = nil
    assert !@instance.valid?
    @instance.uid = "test"
    assert @instance.valid?
  end

  test "uid must be unique" do
    uid = @instance.uid
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
    unit.administering_users << @instance
    unit.save!
    assert @instance.unit_admin?(unit)
  end

  test "unit_admin?() returns true when the user belongs to a user group that
  is allowed to administer the given unit" do
    group = user_groups(:temp)
    @instance.user_groups << group
    unit = units(:unit1)
    unit.administering_groups << group
    assert @instance.unit_admin?(unit)
  end

  test "unit_admin?() returns false when the user is not an administrator of
  the given unit" do
    assert !@instance.unit_admin?(units(:unit1))
  end

end
