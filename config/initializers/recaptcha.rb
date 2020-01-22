# config/initializers/recaptcha.rb

require 'configuration'

config     = ::Configuration.instance
site_key   = config.recaptcha[:site_key]
secret_key = config.recaptcha[:secret_key]

Recaptcha.configure do |recaptcha|
  recaptcha.site_key   = site_key
  recaptcha.secret_key = secret_key
end
