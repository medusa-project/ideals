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

  # effective_manager?()

  test "effective_manager?() returns true when the user is a sysadmin" do
    @instance = users(:admin)
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
    @instance = users(:admin)
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

  # effective_unit_admin?()

  test "effective_unit_admin?() returns true when the user is a sysadmin" do
    @instance = users(:admin)
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

  # manager?()

  test "manager?() returns true when the user is a manager of the given collection" do
    collection = collections(:collection1)
    collection.managing_users << @instance
    collection.save!
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

  test "submitter?() returns true when the user is a submitter in the given collection" do
    collection = collections(:collection1)
    collection.submitting_users << @instance
    collection.save!
    assert @instance.submitter?(collection)
  end

  test "submitter?() returns false when the user is not a submitter in the given collection" do
    assert !@instance.submitter?(collections(:collection1))
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

  test "unit_admin?() returns true when the user is an administrator of the
  given unit" do
    unit = units(:unit1)
    unit.administering_users << @instance
    unit.save!
    assert @instance.unit_admin?(unit)
  end

  test "unit_admin?() returns false when the user is not an administrator of
  the given unit" do
    assert !@instance.unit_admin?(units(:unit1))
  end

end
