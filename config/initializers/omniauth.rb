OmniAuth.config.logger = Rails.logger

SAML_SETUP_PROC = lambda do |env|
  request     = Rack::Request.new(env)
  institution = Institution.find_by_fqdn(request.host_with_port)
  unless institution.saml_auth_enabled
    raise "This institution does not support SAML authentication."
  end
  s = env['omniauth.strategy']
  s.options[:sp_entity_id]                       = institution.saml_sp_entity_id
  s.options[:idp_sso_service_url]                = institution.saml_idp_sso_service_url
  s.options[:idp_sso_service_url_runtime_params] = { original_request_param: :mapped_idp_param }
  s.options[:idp_cert]                           = institution.saml_idp_cert
  s.options[:name_identifier_format]             = "urn:oasis:names:tc:SAML:1.1:nameid-format:emailAddress"
end

SHIBBOLETH_SETUP_PROC = lambda do |env|
  request     = Rack::Request.new(env)
  institution = Institution.find_by_fqdn(request.host_with_port)
  unless institution.shibboleth_auth_enabled
    raise "This institution does not support Shibboleth authentication."
  end
  env['omniauth.strategy'].options = {
    request_type: "params",
    uid_field:    "eppn",
    info_fields:  {
      name:  institution.shibboleth_name_attribute,
      email: institution.shibboleth_email_attribute
    },
    extra_fields: institution.shibboleth_extra_attributes
  }
end

Rails.application.config.middleware.use OmniAuth::Builder do
  # The identity provider (for local password logins) is available in all
  # environments.
  provider :identity,
           model:                  LocalIdentity,
           fields:                 [:email, :name],
           locate_conditions:      -> (req) { { model.auth_key => req['auth_key']&.downcase } },
           on_failed_registration: WelcomeController.action(:on_failed_registration) # TODO: we aren't using this

  # The Shibboleth (UIUC) developer provider is available only in development
  # and test.
  if Rails.env.development? || Rails.env.test?
    provider :developer
  else
    # The real Shibboleth provider is available in all other environments.
    # N.B.: this provider is added here, but it needs further setup at request
    # time as its properties will vary depending on which institution's host is
    # being accessed.
    # See: https://github.com/omniauth/omniauth/wiki/Setup-Phase
    provider :shibboleth, setup: SHIBBOLETH_SETUP_PROC
  end

  # SAML (everybody else) is available in all environments.
  # N.B.: this provider is added here, but it needs further setup at request
  # time as its properties will vary depending on which institution's host is
  # being accessed.
  # See: https://github.com/omniauth/omniauth/wiki/Setup-Phase
  provider :saml, setup: SAML_SETUP_PROC
end

OmniAuth.config.on_failure = Proc.new { |env|
  OmniAuth::FailureEndpoint.new(env).redirect_to_failure
}
