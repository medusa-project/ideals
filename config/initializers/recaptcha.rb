# config/initializers/recaptcha.rb

require 'configuration'

puts Rails.env
=begin
config = ::Configuration.instance

Recaptcha.configure do |recaptcha|
  recaptcha.site_key   = config.recaptcha[:site_key]
  recaptcha.secret_key = config.recaptcha[:secret_key]
end
=end
