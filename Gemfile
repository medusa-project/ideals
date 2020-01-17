# frozen_string_literal: true

source "https://rubygems.org"
git_source(:github) {|repo| "https://github.com/#{repo}.git" }

ruby "2.6.3"

# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem "rails", "~> 6.0.2.1"
# Use postgresql as the database for Active Record
gem "pg", ">= 0.18", "< 2.0"
# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
gem "jbuilder", "~> 2.5"
# Use Redis adapter to run Action Cable in production
# gem 'redis', '~> 4.0'
# Use ActiveModel has_secure_password
gem "bcrypt", "~> 3.1.7"

# Use pundit for authorization
gem "pundit"

# Use SCSS for stylesheets
gem "sass-rails", "~> 5.0"

# Use Uglifier as compressor for JavaScript assets
gem "uglifier", ">= 2.7.2"

# Use jquery as the JavaScript library
gem "highcharts-rails"
gem "jquery-rails"
gem "jquery-ui-rails"

# Use in-house storage gem to manage flexible storage on filesystems and s3 buckets
gem "medusa_storage", git: "https://github.com/medusa-project/medusa_storage.git", branch: "master"

# Use aws-sdk to manage signed urls for downloads
gem "aws-sdk"

# Use browser to detect request browser
gem "browser", "~> 1.1"

# Use tus-server to support chunked uploads of large files
gem "tus-server"

# Use reCAPTCHA API to reduce spam in contact form
gem "recaptcha"

# Use filemagic to detect file types
gem "ruby-filemagic", "~> 0.7.2"

# Use rubyzip to stream dynamically generated zip files
gem "rubyzip"
gem "zipline"

# Use seven_zip_ruby to handle 7zip archives
gem "seven_zip_ruby", "~> 1.2", ">= 1.2.5"

# Use minitar to deal with POSIX tar archive files
gem "minitar", "~> 0.6.1"

# Use rchardet to attempt to detect character encoding
gem "rchardet"

# Use roda for routing magic
gem "roda"

# Use figaro to set environment variables
gem "figaro"

# Use bootstrap for layout framework
gem "autoprefixer-rails"
gem 'bootstrap', '~> 4.4'
gem "font-awesome-sass", "~> 5.6.1"
gem 'scars-bootstrap-theme', github: 'medusa-project/scars-bootstrap-theme'

gem "haml"
gem "haml-rails"

gem "uuid"

gem "open_uri_redirections"

gem "simple_form"

gem "mime-types", require: "mime/types/full"

# Use 'rest-client' to interaction with file processor api
gem "rest-client"

gem "equivalent-xml"
gem "nokogiri"
gem "nokogiri-diff"

gem "progress_bar"

# Use email validator for model
gem "valid_email"

# Use identity strategy to create local accounts for testing
gem "omniauth-identity"
gem "omniauth-shibboleth"

gem "omniauth-rails_csrf_protection"

# Use Boxr to interact with Box API
gem "boxr"

# Use delayed_job during upload and ingest from box to avoid timeout failures
gem "daemons"
gem "delayed_job_active_record"
gem "progress_job"
# gem 'delayed_job_heartbeat_plugin'

# Use bunny to handle RabbitMQ messages
gem "bunny", "2.8.1"

# Use builder to support sitemaps generator
gem "builder", "~> 3.2", ">= 3.2.2"

# Use curb to wrap curl
gem "curb", "~> 0.9.4"

# Use modernizr-rails to handle different browsers differently
gem "modernizr-rails"

# use rubocop linter to support consisitent style
gem "rubocop", require: false
gem "rubocop-performance"
gem "rubocop-rails"

group :development do
  # Reduces boot times through caching; required in config/boot.rb
  gem "bootsnap", ">= 1.1.0", require: false
  # Use Capistrano for deployment
  gem "capistrano-bundler"
  gem "capistrano-passenger"
  gem "capistrano-rails"
  gem "capistrano-rbenv"
  gem "puma"
end

group :test do
  # Adds support for Capybara system testing and selenium driver
  gem "capybara", ">= 2.15"
  gem "selenium-webdriver"
  # Easy installation and use of chromedriver to run system tests with Chrome
  gem "chromedriver-helper"
  # Use DatabaseCleaner to clean the database (because transactional fixtures do not work with Selenium)
  gem "database_cleaner"
  # Use mocha to support stubs for testing
  gem "mocha", "~> 1.1"
  # Use rspec-rails to support testing
  gem "rspec-rails", "~> 3.5"
  # Use Cucumber for behavior testing
  gem "cucumber-rails", require: false
end

group :production do
  # Use Passenger standalone
  gem "passenger", require: "phusion_passenger/rack_handler"
end

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem "tzinfo-data", platforms: [:mingw, :mswin, :x64_mingw, :jruby]
