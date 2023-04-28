OmniAuth.config.logger = Rails.logger

Rails.application.config.middleware.use OmniAuth::Builder do
  # The identity provider (for local password logins) is available in all
  # environments.
  provider :identity,
           model:                  LocalIdentity,
           fields:                 [:email, :name],
           locate_conditions:      -> (req) { { model.auth_key => req['auth_key']&.downcase } },
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
           sp_entity_id:                       "bagel-ir",
           idp_sso_service_url:                "https://login.openathens.net/saml/2/sso/rmu.edu",
           idp_sso_service_url_runtime_params: { original_request_param: :mapped_idp_param },
           idp_slo_service_url:                 "https://login.openathens.net/signout",
           # from OA metadata: https://login.openathens.net/saml/2/metadata-idp/rmu.edu
           idp_cert:                           "-----BEGIN CERTIFICATE-----\nMIIDvjCCAqagAwIBAgIEVOxCIjANBgkqhkiG9w0BAQsFADCBoDEoMCYGCSqGSIb3DQEJARYZYXRoZW5zaGVscEBlZHVzZXJ2Lm9yZy51azELMAkGA1UEBhMCR0IxETAPBgNVBAgMCFNvbWVyc2V0MQ0wCwYDVQQHDARCYXRoMRAwDgYDVQQKDAdFZHVzZXJ2MRMwEQYDVQQLDApPcGVuQXRoZW5zMR4wHAYDVQQDDBVnYXRld2F5LmF0aGVuc2Ftcy5uZXQwHhcNMTUwMjI0MDkyMDA2WhcNMjUwMjI0MDkyMDA2WjCBoDEoMCYGCSqGSIb3DQEJARYZYXRoZW5zaGVscEBlZHVzZXJ2Lm9yZy51azELMAkGA1UEBhMCR0IxETAPBgNVBAgMCFNvbWVyc2V0MQ0wCwYDVQQHDARCYXRoMRAwDgYDVQQKDAdFZHVzZXJ2MRMwEQYDVQQLDApPcGVuQXRoZW5zMR4wHAYDVQQDDBVnYXRld2F5LmF0aGVuc2Ftcy5uZXQwggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQCandpa4o0Njtw1DqbrrNTfOVe1PqyXIIVmDrJ6VUR/mokXXu+m5Gm+1f+3lyN5IA2YMn9Z8Yo37JQjIHs+xVS3q4nT1ewS7S3en1pdXKsH1WnUnVWUmpl9WJZrUwi5i8X80LNyr7PmudhuKNEATGUXkA/xWCkk2d8jf91hy7Qu+HA8LOKtdbbNigErh2IY/YuNWUVUqgGbMH5BGr7ZEhPrz+Vwcf9lhPW+tKpKpZEzJfQiq8EoPaeMXEpKWBEErm67gkWFCA5VhfcJLqFjQEC3pWOxt5rZVS8gl/Z33VSJZVzY5jWcQzmGaLXPHXyiKPmixl6+DjGlUM0ylNF7GvtDAgMBAAEwDQYJKoZIhvcNAQELBQADggEBAFhmhujLZueiJ6F7mQCpfB0Hj4Y8FyFUUc8NMAt5Set7H4DKSSl4shcqisZBa5yTdyenYwkmBszvCWs6Yeep+zJmCR62cb/f1M32oMzLm02OlznWMkE8/IajGmdxTnB6Z/XcdMMIiCeok4kqe5KMd5oRAyNskHYZ+8kzhs2zTveR+rqCtYxa/AYpwf7n0VQR9clBSNCIT4BCRi10aPE531VIxl4ljY3CwNoZ4lQTU/0aj8O4j68V2neiQb8lewAii0b2xoyOGYP4okd7T2tl4gl2noVbCvYNjd6GYze/w4lgwiemkby7wu5sN1lEudgKDV+H54wU29ZIyDEFM6DDNE4=\n-----END CERTIFICATE-----",
           name_identifier_format:             "urn:oasis:names:tc:SAML:1.1:nameid-format:emailAddress"
end

OmniAuth.config.on_failure = Proc.new { |env|
  OmniAuth::FailureEndpoint.new(env).redirect_to_failure
}
