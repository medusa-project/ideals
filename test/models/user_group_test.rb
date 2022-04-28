require 'test_helper'

class UserGroupTest < ActiveSupport::TestCase

  setup do
    @instance = user_groups(:sysadmin)
    assert @instance.valid?
  end

  # all_matching_hostname_or_ip()

  test "all_matching_hostname_or_ip() returns the correct groups" do
    @instance.hosts << Host.new(pattern: "something.edu")
    @instance.save!

    groups = UserGroup.all_matching_hostname_or_ip("something.edu", "10.0.0.1")
    assert_equal 1, groups.length

    groups = UserGroup.all_matching_hostname_or_ip("somethingelse.edu", "10.0.0.1")
    assert_equal 0, groups.length
  end

  # sysadmin()

  test "sysadmin() returns the sysadmin group" do
    assert_not_nil UserGroup.sysadmin
  end

  # all_users()

  test "all_users() returns associated LocalUsers" do
    assert @instance.all_users.include?(users(:local_sysadmin))
  end

  test "all_users() returns ShibbolethUsers belonging to an associated AD group" do
    assert @instance.all_users.include?(users(:uiuc_admin))
  end

  # includes?()

  test "includes?() returns false for a user not associated with the instance" do
    assert !@instance.includes?(users(:norights))
  end

  test "includes?() returns true for a user directly associated with the
  instance" do
    user             = users(:norights)
    @instance.users << user
    assert @instance.includes?(user)
  end

  test "includes?() returns true for a user whose email address matches a
  pattern on the instance" do
    user = users(:norights)
    @instance.email_patterns.build(pattern: "example.edu").save!
    assert @instance.includes?(user)
  end

  test "includes?() returns true for a user belonging to an AD group associated
  with the instance" do
    user         = users(:uiuc)
    group        = @instance.ad_groups.first
    group.users << user
    group.save!
    assert @instance.includes?(user)
  end

  test "includes?() returns true for a user belonging to a department associated
  with the instance" do
    user                   = users(:uiuc)
    user.department        = departments(:basket_weaving)
    @instance.departments << user.department

    assert @instance.includes?(user)
  end

  test "includes?() returns true for a user belonging to a department associated
  with the instance and an affiliation associated with the instance" do
    user                    = users(:uiuc)
    user.department         = departments(:basket_weaving)
    user.affiliation        = affiliations(:phd_student)
    @instance.departments  << user.department
    @instance.affiliations << user.affiliation

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

end
