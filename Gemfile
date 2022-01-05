# frozen_string_literal: true

source "https://rubygems.org"
git_source(:github) {|repo| "https://github.com/#{repo}.git" }

ruby "3.0.3"

gem "autoprefixer-rails"
gem "aws-sdk-s3", "~> 1"
# Use ActiveModel has_secure_password for local identity users
gem "bcrypt", "~> 3.1.7"
# No Bootstrap! This is provided by scars-bootstrap-theme.
#gem "bootstrap"
# Handles RabbitMQ messages.
gem "bunny"
gem "amq-protocol"
gem "amqp_helper", "~>0.2.0", git: "https://github.com/medusa-project/amqp_helper.git"
gem "csv"
# Provides all of our icons.
gem "font-awesome-sass", "~> 5"
# All HTML templates are written in HAML
gem "haml"
gem "haml-rails"
# Application HTTP client
gem "httpclient"
# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
gem "jbuilder", "~> 2.5"
# Use jquery as the JavaScript library
gem "jquery-rails"
gem "js_cookie_rails"
# For pretty absolute and relative dates
gem "local_time"
# High-level access to the Medusa Collection Registry's REST API
#gem "medusa-client", path: "/Users/alexd/Projects/GitHub/medusa-project/medusa-client"
gem "medusa-client", git: "https://github.com/medusa-project/medusa-client.git"
# JavaScript runtime
gem "mini_racer", "~> 0.4.0", platforms: :ruby
# Use modernizr-rails to handle different browsers differently
gem "modernizr-rails"
# Used to copy files (bitstreams) out of IDEALS-DSpace during a migration.
gem "net-scp"
# Assists in parsing IP address CIDR ranges.
gem "netaddr"
# Enables local identity logins.
gem "omniauth-identity"
# Enables Shibboleth logins.
gem "omniauth-shibboleth"
# Our database
gem "pg"
# Our application server
gem "puma"
gem "rails", "~> 7.0"
# Used during the new user sign-up process
gem "recaptcha"
# Use SCSS for stylesheets
gem "sassc"
# Provides a SCARS-themed Bootstrap.
gem "scars-bootstrap-theme", github: "medusa-project/scars-bootstrap-theme", branch: "release/bootstrap-4.4"
#gem "scars-bootstrap-theme", path: "../scars-bootstrap-theme"
gem "sprockets-rails"
# Use Uglifier as compressor for JavaScript assets
gem "uglifier", ">= 2.7.2"

group :development do
  # Reduces boot times through caching; required in config/boot.rb
  #gem "bootsnap", ">= 1.1.0", require: false
  # Use Capistrano for deployment
  gem "capistrano-bundler"
  gem "capistrano-rails"
  gem "capistrano-rbenv"
  # use rubocop linter to support consistent style
  gem "rubocop", require: false
  gem "rubocop-performance"
  gem "rubocop-rails"
  gem 'yard'
end

group :production do
  gem "omniauth-rails_csrf_protection"
end

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
#gem "tzinfo-data", platforms: [:mingw, :mswin, :x64_mingw, :jruby]
