require "test_helper"

class LocalUserTest < ActiveSupport::TestCase

  setup do
    @instance = users(:norights)
  end

  # destroy()

  test "destroy() destroys the associated Identity" do
    identity = @instance.identity
    @instance.destroy!

    assert_raises ActiveRecord::RecordNotFound do
      identity.reload
    end
  end

  # save()

  test "save() updates the email of the associated Identity" do
    new_email = "new@example.edu"
    @instance.update!(email: new_email)
    assert_equal new_email, @instance.identity.email
  end

  test "save() updates the name of the associated Identity" do
    new_name = "New Name"
    @instance.update!(name: new_name)
    assert_equal new_name, @instance.identity.name
  end

  # sysadmin?()

  test "sysadmin?() returns true when the user is sysadmin" do
    assert users(:admin).sysadmin?
  end

  test "sysadmin?() returns false when the user is not a sysadmin" do
    assert !@instance.sysadmin?
  end

end
