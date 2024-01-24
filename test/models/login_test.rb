require "test_helper"

class LoginTest < ActiveSupport::TestCase

  class ProviderTest < ActiveSupport::TestCase

    test "all() returns all providers" do
      assert_equal [0, 2], Login::Provider.all
    end

    test "label_for() returns a correct value" do
      assert_equal "Local", Login::Provider.label_for(Login::Provider::LOCAL)
      assert_equal "Shibboleth", Login::Provider.label_for(1)
      assert_equal "SAML", Login::Provider.label_for(Login::Provider::SAML)
    end

  end

  setup do
    @instance = Login.new
  end

  # create()

  test "create() creates an associated Event" do
    assert_difference "Event.count" do
      login = Login.create!(provider:    Login::Provider::LOCAL,
                            institution: institutions(:southwest),
                            user:        users(:southwest))
      event = Event.all.order(created_at: :desc).limit(1).first
      assert_equal event.login, login
    end
  end

  # auth_hash=()

  test "auth_hash=() sets the provider" do
    @instance.auth_hash = { provider: "saml" }
    assert_equal Login::Provider::SAML, @instance.provider

    @instance.auth_hash = { provider: "developer" }
    assert_equal Login::Provider::SAML, @instance.provider

    @instance.auth_hash = { provider: "identity" }
    assert_equal Login::Provider::LOCAL, @instance.provider
  end

end
