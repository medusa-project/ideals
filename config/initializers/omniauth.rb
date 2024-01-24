OmniAuth.config.logger = Rails.logger

# The SAML provider's setup-phase proc. See below.
SAML_SETUP_PROC = lambda do |env|
  request     = Rack::Request.new(env)
  institution = Institution.find_by_fqdn(request.host_with_port)
  unless institution.saml_auth_enabled
    raise "This institution does not support SAML authentication."
  end
  s = env['omniauth.strategy']
  # N.B.: Most of these options are documented here:
  # https://github.com/SAML-Toolkits/ruby-saml
  s.options[:sp_entity_id]                       = institution.saml_sp_entity_id
  case institution.saml_idp_sso_binding_urn
  when "urn:oasis:names:tc:SAML:2.0:bindings:HTTP-Redirect"
    s.options[:idp_sso_service_url]              = institution.saml_idp_sso_redirect_service_url
  else
    s.options[:idp_sso_service_url]              = institution.saml_idp_sso_post_service_url
  end
  s.options[:idp_sso_service_binding]            = institution.saml_idp_sso_binding_urn
  s.options[:idp_sso_service_url_runtime_params] = {
    original_request_param: :mapped_idp_param
  }
  s.options[:idp_cert_multi]                     = {
    signing:    [
      institution.saml_idp_signing_cert,
      institution.saml_idp_signing_cert2
    ].select(&:present?),
    encryption: [
      institution.saml_idp_encryption_cert,
      institution.saml_idp_encryption_cert2
    ].select(&:present?)
  }
  s.options[:certificate]                        = institution.saml_sp_public_cert
  s.options[:private_key]                        = institution.saml_sp_private_key
  if institution.saml_sp_next_public_cert.present?
    s.options[:certificate_new]                  = institution.saml_sp_next_public_cert
  end
  if institution.saml_sp_public_cert.present?
    s.options[:security]                         = { want_assertions_encrypted: true }
  end
  s.options[:name_identifier_format]             = "urn:oasis:names:tc:SAML:1.1:nameid-format:emailAddress"
end

Rails.application.config.middleware.use OmniAuth::Builder do
  # The developer provider is available only in development and test.
  if Rails.env.development? || Rails.env.test?
    provider :developer
  end

  # The identity provider (for local password logins) is available in all
  # environments.
  provider :identity,
           model:                  Credential,
           fields:                 [:email, :name],
           locate_conditions:      -> (request) { { model.auth_key => request.params['auth_key']&.downcase } }

  # SAML (everybody else) is available in all environments.
  # N.B.: this provider needs further setup at request time, as its properties
  # will vary depending on which institution's host is being accessed.
  # See: https://github.com/omniauth/omniauth/wiki/Setup-Phase
  provider :saml, setup: SAML_SETUP_PROC
end

OmniAuth.config.on_failure = Proc.new { |env|
  OmniAuth::FailureEndpoint.new(env).redirect_to_failure
}
