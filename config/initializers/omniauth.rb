OmniAuth.config.logger = Rails.logger

Rails.application.config.middleware.use OmniAuth::Builder do
  # The identity provider (for local password logins) is available in all
  # environments.
  provider :identity,
           model: LocalIdentity,
           fields: [:email, :name],
           locate_conditions: -> (req) { { model.auth_key => req['auth_key']&.downcase } },
           on_failed_registration: WelcomeController.action(:on_failed_registration) # TODO: we aren't using this

  # The developer provider (for Shibboleth dev/test auth) is available only in
  # development and test.
  if Rails.env.development? || Rails.env.test?
    provider :developer
  else
    # Shibboleth (UIUC) is available in all other environments.
    shib_opts = YAML.load_file(File.join(Rails.root, 'config', 'shibboleth.yml'))[Rails.env]
    provider :shibboleth, shib_opts.symbolize_keys
  end

  # SAML (everybody else) is available in all environments.
  provider :saml,
           assertion_consumer_service_url:     "https://demo.ideals.illinois.edu/auth/saml",
           sp_entity_id:                       "ideals",
           idp_sso_service_url:                "https://example.edu",
           idp_sso_service_url_runtime_params: {:original_request_param => :mapped_idp_param},
           # only need this or fingerprint, not both
           idp_cert:                           "-----BEGIN CERTIFICATE-----\n...-----END CERTIFICATE-----",
           idp_cert_multi:                     {
             signing:    ["-----BEGIN CERTIFICATE-----\n...-----END CERTIFICATE-----", "-----BEGIN CERTIFICATE-----\n...-----END CERTIFICATE-----"],
             encryption: []
           },
           idp_cert_fingerprint:           "E7:91:B2:E1:...",
           idp_cert_fingerprint_validator: lambda { |fingerprint| fingerprint },
           name_identifier_format:         "urn:oasis:names:tc:SAML:1.1:nameid-format:emailAddress"
end

OmniAuth.config.on_failure = Proc.new { |env|
  OmniAuth::FailureEndpoint.new(env).redirect_to_failure
}
