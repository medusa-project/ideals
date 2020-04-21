# https://github.com/ambethia/recaptcha

require 'configuration'

app_config = ::Configuration.instance

Recaptcha.configure do |config|
  config.site_key   = app_config.recaptcha[:site_key]
  config.secret_key = app_config.recaptcha[:secret_key]
end
