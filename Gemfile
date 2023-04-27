# frozen_string_literal: true

source "https://rubygems.org"
git_source(:github) {|repo| "https://github.com/#{repo}.git" }

ruby "3.2.2"

# We store our sessions in the database. (The Rails default is to store them
# in an encrypted cookie, but we've run into problems with the 4KB cookie size
# limit.)
gem "activerecord-session_store"
gem "aws-sdk-s3", "~> 1"
# Use ActiveModel has_secure_password for local identity users
gem "bcrypt", "~> 3"
gem "bootstrap", "~> 5.2"
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
# Assists in converting non-Unicode text during full text extraction
gem "iconv"
# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
gem "jbuilder"
# Use jquery as the JavaScript library
gem "jquery-rails"
gem "js_cookie_rails"
# For pretty absolute and relative dates
gem "local_time"
# High-level access to the Medusa Collection Registry's REST API
#gem "medusa-client", path: "/Users/alexd/Projects/GitHub/medusa-project/medusa-client"
gem "medusa-client", git: "https://github.com/medusa-project/medusa-client.git"
# JavaScript runtime
gem "mini_racer", platforms: :ruby
# Helps sort bitstreams by filename
gem "natural_sort"
# Assists in parsing IP address CIDR ranges.
gem "netaddr"
# Enables local identity logins.
gem "omniauth-identity"
gem "omniauth-rails_csrf_protection"
gem "omniauth-saml"
gem "omniauth-shibboleth"
# Our database
gem "pg"
# Our application server
gem "puma"
gem "rails", "~> 7.0"
# Use SCSS for stylesheets
gem "sassc"
gem "sprockets-rails"
gem "tzinfo-data"
# Use Uglifier as compressor for JavaScript assets
gem "uglifier", ">= 2.7.2"
gem 'uiuc_lib_ad', git: 'https://github.com/UIUCLibrary/uiuc_lib_ad.git'

group :development do
  # Reduces boot times through caching; required in config/boot.rb
  #gem "bootsnap", ">= 1.1.0", require: false
  # Use Capistrano for deployment
  gem "capistrano-bundler"
  gem "capistrano-rails"
  gem "capistrano-rbenv"
  gem 'yard'
end
