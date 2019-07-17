# config/initializers/recaptcha.rb
Recaptcha.configure do |config|
  config.site_key  = IDEALS_CONFIG[:recaptcha][:site_key]
  config.secret_key = IDEALS_CONFIG[:recaptcha][:secret_key]
end