# frozen_string_literal: true

source "https://rubygems.org"
git_source(:github) {|repo| "https://github.com/#{repo}.git" }

ruby "2.6.3"

# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem "rails", "~> 6.0.2.1"

gem 'aws-sdk-s3', '~> 1'
# Use ActiveModel has_secure_password for local identity users
gem "bcrypt", "~> 3.1.7"
# Use bootstrap for layout framework
gem 'bootstrap', '~> 4.4' # TODO: does scars-bootstrap-theme provide this?
# Use Boxr to interact with Box API
# gem "boxr"
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
gem "jquery-ui-rails"
gem "js_cookie_rails"
# For pretty absolute and relative dates
gem "local_time"
# JavaScript runtime
gem 'mini_racer', platforms: :ruby
# Enables local identity logins.
gem "omniauth-identity"
# Enables Shibboleth logins.
gem "omniauth-shibboleth"
gem "omniauth-rails_csrf_protection"
# Use postgresql as the database for Active Record
gem "pg"
# Use pundit for authorization
gem "pundit"
# Use SCSS for stylesheets
gem "sassc"
# Provides the website theme.
gem 'scars-bootstrap-theme', github: 'medusa-project/scars-bootstrap-theme'
# Use Uglifier as compressor for JavaScript assets
gem "uglifier", ">= 2.7.2"

# Use delayed_job during upload and ingest from box to avoid timeout failures
gem "daemons"
gem "delayed_job_active_record"
gem "progress_job"
# gem 'delayed_job_heartbeat_plugin'

# Use bunny to handle RabbitMQ messages
gem "bunny", "2.8.1"

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
  # Use Passenger standalone
  gem "passenger", require: "phusion_passenger/rack_handler"
end

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
#gem "tzinfo-data", platforms: [:mingw, :mswin, :x64_mingw, :jruby]
