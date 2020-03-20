require 'test_helper'

class UserTest < ActiveSupport::TestCase

  setup do
    setup_elasticsearch
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

  # as_indexed_json()

  test "as_indexed_json() returns the correct structure" do
    doc = @instance.as_indexed_json
    assert_equal ["User", "IdentityUser"],
                 doc[User::IndexFields::CLASS]
    assert_not_empty doc[User::IndexFields::CREATED]
    assert_equal @instance.email,
                 doc[User::IndexFields::EMAIL]
    assert_not_empty doc[User::IndexFields::LAST_INDEXED]
    assert_equal @instance.updated_at.utc.iso8601,
                 doc[User::IndexFields::LAST_MODIFIED]
    assert_equal @instance.name,
                 doc[User::IndexFields::NAME]
    assert_equal @instance.username,
                 doc[User::IndexFields::USERNAME]
  end

  # delete_document() (Indexed concern)

  test "delete_document() deletes a document" do
    users = User.all.limit(5)
    users.each(&:reindex)
    refresh_elasticsearch
    count = User.search.count
    assert count > 0

    User.delete_document(users.first.index_id)
    refresh_elasticsearch
    assert_equal count - 1, User.search.count
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

  # reindex() (Indexed concern)

  test "reindex() reindexes the instance" do
    setup_elasticsearch
    assert_equal 0, User.search.filter(User::IndexFields::ID, @instance.index_id).count

    @instance.reindex
    refresh_elasticsearch

    assert_equal 1, User.search.filter(User::IndexFields::ID, @instance.index_id).count
  end

  # reindex_all() (Indexed concern)

  test "reindex_all() reindexes all users" do
    setup_elasticsearch
    assert_equal 0, User.search.count

    User.reindex_all
    refresh_elasticsearch

    expected = User.all.count
    actual = User.search.count
    assert actual > 0
    assert_equal expected, actual
  end

  # search() (Indexed concern)

  test "search() returns a UserRelation" do
    assert_kind_of UserRelation, User.search
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
