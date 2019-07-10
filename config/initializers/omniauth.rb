shib_opts = YAML.load_file(File.join(Rails.root, 'config', 'shibboleth.yml'))[Rails.env]

Rails.application.config.middleware.use OmniAuth::Builder do

  # provider :developer unless Rails.env.production?
  provider :shibboleth, shib_opts.symbolize_keys

end

OmniAuth.config.on_failure = Proc.new { |env|
  OmniAuth::FailureEndpoint.new(env).redirect_to_failure
}

Ideals::Application.shibboleth_host = shib_opts['host']