require 'test_helper'

class UserGroupTest < ActiveSupport::TestCase

  setup do
    @instance = user_groups(:sysadmin)
    assert @instance.valid?
  end

  # sysadmin()

  test "sysadmin() returns the sysadmin group" do
    assert_not_nil UserGroup.sysadmin
  end

  # all_users()

  test "all_users() returns associated LocalUsers" do
    assert @instance.all_users.include?(users(:local_sysadmin))
  end

  test "all_users() returns ShibbolethUsers belonging to an associated LDAP group" do
    assert @instance.all_users.include?(users(:uiuc_admin))
  end

  # includes?()

  test "includes?() returns false for a user not associated with the group" do
    assert !@instance.includes?(users(:norights))
  end

  test "includes?() returns true for a user directly associated with the group" do
    user = users(:norights)
    @instance.users << user
    assert @instance.includes?(user)
  end

  test "includes?() returns true for a user belonging to an LDAP group
  associated with the group" do
    user  = users(:norights)
    group = @instance.ldap_groups.first
    group.users << user
    assert @instance.includes?(user)
  end

  # key

  test "key must be present" do
    assert_raises ActiveRecord::RecordInvalid do
      @instance.update!(key: "")
    end
  end

  test "key must be unique" do
    assert_raises ActiveRecord::RecordNotUnique do
      UserGroup.create!(key: @instance.key,
                        name: SecureRandom.hex)
    end
  end

  # name

  test "name must be present" do
    assert_raises ActiveRecord::RecordInvalid do
      @instance.update!(name: "")
    end
  end

  test "name must be unique" do
    assert_raises ActiveRecord::RecordNotUnique do
      UserGroup.create!(key: SecureRandom.hex,
                        name: @instance.name)
    end
  end

  # users

  test "users can contain only LocalUsers" do
    @instance.users << users(:local_sysadmin)
    assert @instance.valid?
    @instance.users << users(:uiuc)
    assert !@instance.valid?
  end

end
