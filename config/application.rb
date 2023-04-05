require_relative "boot"

require "rails/all"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Ideals
  class Application < Rails::Application
    attr_accessor :shibboleth_host

    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 7.0

    config.active_record.yaml_column_permitted_classes = [
      OmniAuth::AuthHash,
      OmniAuth::AuthHash::InfoHash,
      Symbol
    ]

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # config.time_zone = "Central Time (US & Canada)"
    # config.eager_load_paths << Rails.root.join("extras")

    # Stop Rails from wrapping invalid form elements in an unwanted div
    ActionView::Base.field_error_proc = proc do |html_tag, instance|
      html_tag.gsub("form-control", "form-control is-invalid").html_safe
    end
  end
end
