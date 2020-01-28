# frozen_string_literal: true

ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"

class ActiveSupport::TestCase
  # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
  fixtures :all

  def refresh_elasticsearch
    client = ElasticsearchClient.instance
    client.refresh(Configuration.instance.elasticsearch[:index])
  end

  def setup_elasticsearch
    index = Configuration.instance.elasticsearch[:index]
    client = ElasticsearchClient.instance
    client.delete_index(index, false)
    client.create_index(index)
  end

  def log_in_as(user)
    post '/auth/identity/callback', params: {
        auth_key: "#{user.username}@illinois.edu",
        password: "password"
    }
  end

  def log_out
    delete logout_path
  end

end
