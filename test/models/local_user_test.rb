require "test_helper"

class LocalUserTest < ActiveSupport::TestCase

  setup do
    @instance = users(:norights)
  end

  # create_manually()

  test "create_manually() creates a correct instance" do
    email       = "test@example.org"
    name        = "Testy Test"
    password    = LocalIdentity.random_password
    institution = institutions(:southwest)
    user        = LocalUser.create_manually(email:       email,
                                            name:        name,
                                            password:    password,
                                            institution: institution)

    # check the Invitee
    invitee  = Invitee.find_by_email(email)
    assert_equal institution, invitee.institution
    assert invitee.approved?

    # check the LocalIdentity
    identity = invitee.identity
    assert_equal email, identity.email
    assert_equal name, identity.name
    assert identity.activated

    # check the LocalUser
    assert_equal identity, user.identity
    assert_equal email, user.email
    assert_equal name, user.name
    assert_equal email, user.uid
    assert_equal institution, user.institution
    assert !user.sysadmin?
    assert_nil user.phone
  end

  # from_omniauth()

  test "from_omniauth() returns nil if the auth hash is empty" do
    assert_nil LocalUser.from_omniauth({})
  end

  test "from_omniauth() returns nil if the auth hash UID is missing" do
    hash = {
        provider: "identity",
        info: {
            name: "I have no rights",
            email: "norights@example.edu"
        },
        credentials: ""
    }
    assert_nil LocalUser.from_omniauth(hash)
  end

  test "from_omniauth() returns nil if the auth hash email is missing" do
    hash = {
        provider: "identity",
        uid: "norights@example.edu",
        info: {
            name: "I have no rights"
        },
        credentials: ""
    }
    assert_nil LocalUser.from_omniauth(hash)
  end

  test "from_omniauth() returns nil if the associated LocalIdentity is not activated" do
    identity = users(:norights).identity
    identity.update_attribute(:activated, false)

    hash = {
        provider: "identity",
        uid: "norights@example.edu",
        info: {
            name: "I have no rights",
            email: "norights@example.edu"
        },
        credentials: ""
    }
    assert_nil LocalUser.from_omniauth(hash)
  end

  test "from_omniauth() updates stale user attributes" do
    name = "This is my new name"
    hash = {
        provider: "identity",
        uid: "norights@example.edu",
        info: {
            name: name,
            email: "norights@example.edu"
        },
        credentials: ""
    }
    user = LocalUser.from_omniauth(hash)
    assert_equal name, user.name
  end

  test "from_omniauth() returns the relevant LocalUser" do
    hash = {
        provider: "identity",
        uid: "norights@example.edu",
        info: {
            name: "I have no rights",
            email: "norights@example.edu"
        },
        credentials: ""
    }
    assert_equal users(:norights), LocalUser.from_omniauth(hash)
  end

  # activated?()

  test "activated?() returns false when the associated identity has not been
  activated" do
    @instance.identity.update_attribute(:activated, false)
    assert !@instance.activated?
  end

  test "activated?() returns true when the associated identity has been activated" do
    @instance.identity.update_attribute(:activated, true)
    assert @instance.activated?
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

  # sysadmin?()

  test "sysadmin?() returns true when the user belongs to the sysadmin user group" do
    assert users(:local_sysadmin).sysadmin?
  end

  test "sysadmin?() returns false when the user does not belong to the sysadmin
  user group" do
    assert !@instance.sysadmin?
  end

end
