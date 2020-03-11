require 'test_helper'

class IdentityTest < ActiveSupport::TestCase

  # create_for_user()

  test "create_for_user() creates a correct instance" do
    user = User.create!(username: "joe", name: "Joe", email: "joe@example.org")
    identity = Identity.create_for_user(user, "password")
    assert identity.activated
    assert_equal user.name, identity.name
    assert_not_nil identity.password_digest
    assert_not_nil identity.password_confirmation
    assert_not_nil identity.activated_at
  end

end