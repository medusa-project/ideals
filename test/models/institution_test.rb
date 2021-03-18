require 'test_helper'

class InstitutionTest < ActiveSupport::TestCase

  setup do
    @instance = institutions(:somewhere)
    assert @instance.valid?
  end

  # fqdn

  test "fqdn must be present" do
    @instance.fqdn = nil
    assert !@instance.valid?
    @instance.fqdn = ""
    assert !@instance.valid?
  end

  test "fqdn must be a valid FQDN" do
    @instance.fqdn = "-invalid_"
    assert !@instance.valid?
    @instance.fqdn = "host-name.example.org"
    assert @instance.valid?
  end

  # key

  test "key must be present" do
    @instance.key = nil
    assert !@instance.valid?
    @instance.key = ""
    assert !@instance.valid?
  end

  test "key cannot be changed" do
    assert_raises ActiveRecord::RecordInvalid do
      @instance.update!(key: "newvalue")
    end
  end

  # name

  test "name must be present" do
    @instance.name = nil
    assert !@instance.valid?
    @instance.name = ""
    assert !@instance.valid?
  end

  # save()

  test "save() updates the instance properties" do
    @instance.org_dn = "o=New Name,dc=new,dc=edu"
    @instance.save!
    assert_equal "new", @instance.key
    assert_equal "New Name", @instance.name
  end

  test "save() sets all other instances as not-default when the instance is set
  as default" do
    Institution.update_all(default: false)
    @instance = Institution.all.first
    @instance.default = true
    @instance.save!
    assert_equal @instance, Institution.find_by_default(true)
  end

  # url()

  test "url() returns a correct URL" do
    assert_equal "https://#{@instance.fqdn}", @instance.url
  end

  # users()

  test "users() returns all users" do
    assert @instance.users.count > 0
  end

end
