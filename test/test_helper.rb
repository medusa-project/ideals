# frozen_string_literal: true

ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"

class ActiveSupport::TestCase
  # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
  fixtures :all

  def refresh_elasticsearch
    client = ElasticsearchClient.instance
    client.refresh(Configuration.instance.elasticsearch[:index])
  end

  def setup_elasticsearch
    index = Configuration.instance.elasticsearch[:index]
    client = ElasticsearchClient.instance
    client.delete_index(index, false)
    client.create_index(index)
  end

  def log_in_as(user)
    if user.kind_of?(ShibbolethUser)
      # N.B. 1: See "request_type option" section for info about using
      # omniauth-shibboleth in development:
      # https://github.com/toyokazu/omniauth-shibboleth
      #
      # N.B. 2: the keys in the params hash must be present in
      # config/shibboleth.xml.
      post "/auth/shibboleth/callback", params: {
        "Shib-Session-ID":  SecureRandom.hex,
        eppn:               user.uid,
        displayName:        user.name,
        mail:               user.email,
        "org-dn":           user.org_dn,
        overwriteUserAttrs: "false"
      }
    else
      post "/auth/identity/callback", params: {
        auth_key: user.email,
        password: "password"
      }
    end
  end

  def log_out
    delete logout_path
  end

end
