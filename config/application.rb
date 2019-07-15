require_relative 'boot'

require "rails"
# Pick the frameworks you want:
require "active_model/railtie"
require "active_job/railtie"
require "active_record/railtie"
require "active_storage/engine"
require "action_controller/railtie"
require "action_mailer/railtie"
require "action_view/railtie"
require "action_cable/engine"
# require "sprockets/railtie"
require "rails/test_unit/railtie"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

class UserRole
  ADMIN = 'admin'
  DEPOSITOR = 'depositor'
  GUEST = 'guest'
  NO_DEPOSIT = 'no_deposit'
end

module Ideals
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 5.2

    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration can go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded after loading
    # the framework and any gems in your application.

    attr_accessor :shibboleth_host

    attr_accessor :file_mode

    attr_accessor :settings

    attr_accessor :storage_manager

    attr_accessor :aws_signer

    attr_accessor :aws_client

    config.autoload_paths << File.join(Rails.root, 'lib')
    config.autoload_paths << File.join(Rails.root, 'lib', 'user')

  end
end

#establish a short cut for the Application object
Application = Ideals::Application