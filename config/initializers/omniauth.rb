shib_opts = YAML.load_file(File.join(Rails.root, 'config', 'shibboleth.yml'))[Rails.env]

OmniAuth.config.logger = Rails.logger

# N.B.: it may be necessary to add OmniAuth::AuthHash and perhaps other classes
# to Rails.application.config.active_record.yaml_column_permitted_classes.

Rails.application.config.middleware.use OmniAuth::Builder do
  # The identity provider is available in all environments.
  provider :identity,
           model: LocalIdentity,
           fields: [:email, :name],
           on_failed_registration: WelcomeController.action(:on_failed_registration)
  # Shibboleth is only available in production & demo. In all other
  # environments, developer is used instead.
  if Rails.env.production? || Rails.env.demo?
    provider :shibboleth, shib_opts.symbolize_keys
  else
    provider :developer
  end
end

OmniAuth.config.on_failure = Proc.new { |env|
  OmniAuth::FailureEndpoint.new(env).redirect_to_failure
}

Ideals::Application.shibboleth_host = shib_opts['host']
