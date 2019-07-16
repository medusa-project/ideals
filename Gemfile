source 'https://rubygems.org'
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby '2.6.3'

# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'rails', '~> 5.2.3'
# Use postgresql as the database for Active Record
gem 'pg', '>= 0.18', '< 2.0'
# Use Puma as the app server
gem 'puma', '~> 3.11'
# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
gem 'jbuilder', '~> 2.5'
# Use Redis adapter to run Action Cable in production
# gem 'redis', '~> 4.0'
# Use ActiveModel has_secure_password
gem 'bcrypt', '~> 3.1.7'

# Use SCSS for stylesheets
gem 'sass-rails', '~> 5.0'

# Use Uglifier as compressor for JavaScript assets
gem 'uglifier', '>= 2.7.2'

# Use jquery as the JavaScript library
gem 'jquery-rails'
gem 'jquery-ui-rails'
gem 'highcharts-rails'

# Reduces boot times through caching; required in config/boot.rb
gem 'bootsnap', '>= 1.1.0', require: false

# Use in-house storage gem to manage flexible storage on filesystems and s3 buckets
gem 'medusa_storage', git: 'https://github.com/medusa-project/medusa_storage.git', branch: 'master'

# Use aws-sdk to manage signed urls for downloads
gem 'aws-sdk'

# Use browser to detect request browser
gem 'browser', '~> 1.1'

# Use tus-server to support chunked uploads of large files
gem "tus-server"

# Use reCAPTCHA API to reduce spam in contact form
gem "recaptcha"

# Use filemagic to detect file types
gem 'ruby-filemagic', '~> 0.7.2'

# Use rubyzip to stream dynamically generated zip files
gem 'rubyzip'
gem 'zipline'

# Use seven_zip_ruby to handle 7zip archives
gem 'seven_zip_ruby', '~> 1.2', '>= 1.2.5'

# Use minitar to deal with POSIX tar archive files
gem 'minitar', '~> 0.6.1'

# Use rchardet to attempt to detect character encoding
gem 'rchardet'

# Use roda for routing magic
gem 'roda'

# Use figaro to set environment variables
gem "figaro"

# Use bootstrap for layout framework
gem 'bootstrap-sass', '~> 3.4.1'
gem 'font-awesome-sass', '~> 5.6.1'
gem 'autoprefixer-rails'

gem 'haml'
gem 'haml-rails'

gem 'uuid'

gem 'open_uri_redirections'

gem 'simple_form'

gem 'mime-types', require: 'mime/types/full'

# Use 'rest-client' to interaction with file processor api
gem 'rest-client'

#gem 'httpclient', git: 'git://github.com/medusa-project/httpclient.git'

gem 'nokogiri'
gem 'nokogiri-diff'
gem 'equivalent-xml'

# use solr for searching
gem 'sunspot_rails'
gem 'sunspot_solr'
gem 'progress_bar'

# use will_paginate for pagination of search results
gem 'will_paginate'
gem 'will_paginate-bootstrap'

# Use Passenger standalone
gem "passenger", ">= 5.0.25", require: "phusion_passenger/rack_handler"

# Use email validator for model
gem 'valid_email'

# Use identity strategy to create local accounts for testing
gem 'omniauth-identity'
gem 'omniauth-shibboleth'

gem 'omniauth-rails_csrf_protection'

# Use Boxr to interact with Box API
gem 'boxr'

# Use delayed_job during upload and ingest from box to avoid timeout failures
gem 'delayed_job_active_record'
gem 'daemons'
gem 'progress_job'
# gem 'delayed_job_heartbeat_plugin'

# Use canan to restrict what resources a given user is allowed to access
gem 'cancancan'

# User bunny to handle RabbitMQ messages
gem "bunny", "2.8.1"

# Use builder to support sitemaps generator
gem 'builder', '~> 3.2', '>= 3.2.2'

# Use curb to wrap curl
gem 'curb', '~> 0.9.4'

# Use modernizr-rails to handle different browsers differently
gem 'modernizr-rails'

# Use mocha to support stubs for testing
gem 'mocha', '~> 1.1'

#Use Selenenium web driver in testing
gem 'selenium-webdriver'

#Use rspec-rails to support testing
gem 'rspec-rails', '~> 3.5'

#Use factory girl for fixtures
# gem 'factory_girl_rails'

#Use Cucumber for behavior testing
gem 'cucumber-rails', :require => false

# Use Capistrano for deployment
gem 'capistrano-rails'
gem 'capistrano-bundler'
gem 'capistrano-rbenv'
gem 'capistrano-passenger'

# use rubocop linter to support consisitent style
gem 'rubocop', require: false
gem 'rubocop-rails'
gem 'rubocop-performance'

group :test do
  # Adds support for Capybara system testing and selenium driver
  gem 'capybara', '>= 2.15'
  gem 'selenium-webdriver'
  # Easy installation and use of chromedriver to run system tests with Chrome
  gem 'chromedriver-helper'
  #Use DatabaseCleaner to clean the database (because transactional fixtures do not work with Selenium)
  gem 'database_cleaner'
end

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem 'tzinfo-data', platforms: [:mingw, :mswin, :x64_mingw, :jruby]
