shib_opts = YAML.load_file(File.join(Rails.root, 'config', 'shibboleth.yml'))[Rails.env]

OmniAuth.config.logger = Rails.logger

Rails.application.config.middleware.use OmniAuth::Builder do
  provider :identity,
           :fields => [:email, :name],
           :on_failed_registration => WelcomeController.action(:on_failed_registration)
  provider :shibboleth, shib_opts.symbolize_keys
end

OmniAuth.config.on_failure = Proc.new { |env|
  OmniAuth::FailureEndpoint.new(env).redirect_to_failure
}

Ideals::Application.shibboleth_host = shib_opts['host']