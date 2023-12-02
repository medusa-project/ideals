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

  # create()

  test "create() ascribes a default key to a non-defining-institution group if
  no key is set" do
    group = UserGroup.create!(name: "New Group")
    assert_not_nil group.key
  end

  test "create() ascribes a default key to a defining-institution group if no
  key is set" do
    group = UserGroup.create!(name: "New Group", defines_institution: true)
    assert_equal UserGroup::DEFINING_INSTITUTION_KEY, group.key
  end

  test "create() does not overwrite the key if one is set" do
    key   = "new"
    group = UserGroup.create!(key: key, name: "New Group")
    assert_equal key, group.key
  end

  # sysadmin()

  test "sysadmin() returns the sysadmin group" do
    assert_not_nil UserGroup.sysadmin
  end

  # defines_institution

  test "setting a group as defining its institution sets all other instances of
  the same institution as not defining their institution" do
    institution = institutions(:southeast)
    assert_equal 1, UserGroup.where(institution:         institution,
                                    defines_institution: true).count
    UserGroup.create!(name:                "New Group",
                      key:                 "new",
                      institution:         institution,
                      defines_institution: true)
    assert_equal 1, UserGroup.where(institution:         institution,
                                    defines_institution: true).count
  end

  # destroy()

  test "destroy() destroys an ordinary group" do
    group = user_groups(:southwest_unused)
    group.destroy!
    assert group.destroyed?
  end

  test "destroy() does not destroy a system-required group" do
    group = user_groups(:sysadmin)
    assert_raises ActiveRecord::RecordNotDestroyed do
      group.destroy!
    end
  end

  # includes?()

  test "includes?() returns false for a user not associated with the instance" do
    assert !@instance.includes?(user: users(:southwest))
  end

  test "includes?() returns true for a user directly associated with the
  instance" do
    user             = users(:southwest)
    @instance.users << user
    assert @instance.includes?(user: user)
  end

  test "includes?() returns true for a user whose email address matches a
  pattern on the instance" do
    user = users(:southwest)
    @instance.email_patterns.build(pattern: "southwest.edu").save!
    assert @instance.includes?(user: user)
  end

  test "includes?() returns true for a user whose client IP matches a pattern
  on the instance" do
    user = users(:southwest)
    @instance.hosts.build(pattern: "132.15.0.0/16").save!
    assert @instance.includes?(user: user, client_ip: "132.15.152.14")
  end

  test "includes?() returns true for a user whose client hostname matches a
  pattern on the instance" do
    user = users(:southwest)
    @instance.hosts.build(pattern: "*.example.org").save!
    assert @instance.includes?(user: user, client_hostname: "host1.example.org")
  end

  test "includes?() returns true for a user belonging to an AD group associated
  with the instance" do
    # In the test environment, a user is considered to be in a group if both
    # the NetID contains "sysadmin" and the user group contains an AD group with
    # the string "sysadmin" in it.
    @instance.ad_groups.build(name: "test sysadmin group")
    user = users(:southwest_sysadmin)
    assert @instance.includes?(user: user)
  end

  test "includes?() returns true for a user belonging to a department associated
  with the instance" do
    user                   = users(:southeast)
    user.department        = departments(:basket_weaving)
    @instance.departments << user.department

    assert @instance.includes?(user: user)
  end

  test "includes?() returns true for a user belonging to a department associated
  with the instance and an affiliation associated with the instance" do
    user                    = users(:southeast)
    user.department         = departments(:basket_weaving)
    user.affiliation        = affiliations(:phd_student)
    @instance.departments  << user.department
    @instance.affiliations << user.affiliation

    assert @instance.includes?(user: user)
  end

  # key

  test "key must be present" do
    assert_raises ActiveRecord::RecordInvalid do
      @instance.update!(key: "")
    end
  end

  test "key must be unique within the same institution" do
    institution = institutions(:southwest)
    UserGroup.create!(key:         "test",
                      name:        SecureRandom.hex,
                      institution: institution)
    assert_raises ActiveRecord::RecordNotUnique do
      UserGroup.create!(key:         "test",
                        name:        SecureRandom.hex,
                        institution: institution)
    end
  end

  test "key can be `sysadmin` within the global scope" do
    group = UserGroup.create!(key:  UserGroup::SYSADMIN_KEY,
                              name: "New Group")
    assert group.valid?
  end

  test "key cannot be `sysadmin` within an institution's scope" do
    institution = institutions(:southwest)
    assert_raises ActiveRecord::RecordInvalid do
      UserGroup.create!(key:         UserGroup::SYSADMIN_KEY,
                        name:        "New Group",
                        institution: institution)
    end
  end

  test "key is normalized" do
    @instance.key = " test  test "
    assert_equal "test test", @instance.key
  end

  # name

  test "name must be present" do
    assert_raises ActiveRecord::RecordInvalid do
      @instance.update!(name: "")
    end
  end

  test "name must be unique within the same institution" do
    institution = institutions(:southwest)
    UserGroup.create!(key:         SecureRandom.hex,
                      name:        "Test",
                      institution: institution)
    assert_raises ActiveRecord::RecordNotUnique do
      UserGroup.create!(key:         SecureRandom.hex,
                        name:        "Test",
                        institution: institution)
    end
  end

  test "name is normalized" do
    @instance.name = " test  test "
    assert_equal "test test", @instance.name
  end

  # required?()

  test "required?() returns true for a system-required group" do
    assert @instance.required?
  end

  test "required?() returns true for a defining-institution group" do
    group = user_groups(:southwest_unused)
    group.defines_institution = true
    assert group.required?
  end

  test "required?() returns false for other groups" do
    group = user_groups(:southwest_unused)
    assert !group.required?
  end

end
