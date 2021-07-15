# frozen_string_literal: true

source "https://rubygems.org"
git_source(:github) {|repo| "https://github.com/#{repo}.git" }

ruby "2.7.2"

gem "rails", "~> 6.0.3"

gem "autoprefixer-rails"
gem 'aws-sdk-s3', '~> 1'
# Use ActiveModel has_secure_password for local identity users
gem "bcrypt", "~> 3.1.7"
# No Bootstrap! This is provided by scars-bootstrap-theme.
#gem "bootstrap"
# Handles RabbitMQ messages.
gem 'bunny'
gem 'amq-protocol'
gem 'amqp_helper', '~>0.2.0', git: 'https://github.com/medusa-project/amqp_helper.git'
gem "csv"
# Provides all of our icons.
gem "font-awesome-sass", "~> 5.6"
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
#gem 'medusa-client', path: '/Users/alexd/Projects/GitHub/medusa-project/medusa-client'
gem 'medusa-client', git: 'https://github.com/medusa-project/medusa-client.git'
# JavaScript runtime
gem 'mini_racer', platforms: :ruby
# Used to copy files (bitstreams) out of IDEALS-DSpace during a migration.
gem 'net-scp'
# Enables local identity logins.
gem "omniauth-identity"
# Enables Shibboleth logins.
gem "omniauth-shibboleth"
# Use postgresql as the database for Active Record
gem "pg"
# Used during the new user sign-up process
gem "recaptcha"
# Use SCSS for stylesheets
gem "sassc"
# Provides a SCARS-themed Bootstrap.
gem 'scars-bootstrap-theme', github: 'medusa-project/scars-bootstrap-theme', branch: 'release/bootstrap-4.4'
#gem 'scars-bootstrap-theme', path: '../scars-bootstrap-theme'
# Use Uglifier as compressor for JavaScript assets
gem "uglifier", ">= 2.7.2"

# Use delayed_job during upload and ingest from box to avoid timeout failures
gem "daemons"
gem "delayed_job_active_record"
gem "progress_job"
# gem 'delayed_job_heartbeat_plugin'

# Use builder to support sitemaps generator
gem "builder", "~> 3.2", ">= 3.2.2"

# Use modernizr-rails to handle different browsers differently
gem "modernizr-rails"

group :development do
  # Reduces boot times through caching; required in config/boot.rb
  #gem "bootsnap", ">= 1.1.0", require: false
  # Use Capistrano for deployment
  gem "capistrano-bundler"
  gem "capistrano-passenger"
  gem "capistrano-rails"
  gem "capistrano-rbenv"
  gem "puma"
  # use rubocop linter to support consisitent style
  gem "rubocop", require: false
  gem "rubocop-performance"
  gem "rubocop-rails"
  gem 'yard'
end

group :production do
  gem "omniauth-rails_csrf_protection"
  gem "passenger", require: "phusion_passenger/rack_handler"
end

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
#gem "tzinfo-data", platforms: [:mingw, :mswin, :x64_mingw, :jruby]
