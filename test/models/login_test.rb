require "test_helper"

class LoginTest < ActiveSupport::TestCase

  setup do
    @instance = Login.new
  end

  # create()

  test "create() creates an associated Event" do
    assert_difference "Event.count" do
      login = Login.create!(provider: Login::Provider::LOCAL,
                            user:     users(:southwest))
      event = Event.all.order(created_at: :desc).limit(1).first
      assert_equal event.login, login
    end
  end

  # auth_hash=()

  test "auth_hash=() sets the provider" do
    @instance.auth_hash = { provider: "saml" }
    assert_equal Login::Provider::SAML, @instance.provider

    @instance.auth_hash = { provider: "shibboleth" }
    assert_equal Login::Provider::SHIBBOLETH, @instance.provider

    @instance.auth_hash = { provider: "developer" }
    assert_equal Login::Provider::SHIBBOLETH, @instance.provider

    @instance.auth_hash = { provider: "identity" }
    assert_equal Login::Provider::LOCAL, @instance.provider
  end

end
