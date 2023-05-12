require "test_helper"

class LoginTest < ActiveSupport::TestCase

  setup do
    @instance = Login.new
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
