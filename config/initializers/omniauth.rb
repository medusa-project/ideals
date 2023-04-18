OmniAuth.config.logger = Rails.logger

Rails.application.config.middleware.use OmniAuth::Builder do
  # The identity provider is available in all environments.
  provider :identity,
           model: LocalIdentity,
           fields: [:email, :name],
           locate_conditions: -> (req) { { model.auth_key => req['auth_key']&.downcase } },
           on_failed_registration: WelcomeController.action(:on_failed_registration) # TODO: we aren't using this
  # Shibboleth is only available in production & demo. In all other
  # environments, developer is used instead.
  if Rails.env.development? || Rails.env.test?
    provider :developer
  else
    shib_opts = YAML.load_file(File.join(Rails.root, 'config', 'shibboleth.yml'))[Rails.env]
    provider :shibboleth, shib_opts.symbolize_keys
  end
end

OmniAuth.config.on_failure = Proc.new { |env|
  OmniAuth::FailureEndpoint.new(env).redirect_to_failure
}
