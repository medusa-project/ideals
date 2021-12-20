# frozen_string_literal: true

ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"

class ActiveSupport::TestCase
  # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
  fixtures :all

  def log_in_as(user)
    if user.kind_of?(ShibbolethUser)
      # N.B. 1: See "request_type option" section for info about using
      # omniauth-shibboleth in development:
      # https://github.com/toyokazu/omniauth-shibboleth
      #
      # N.B. 2: the keys in the params hash must be present in
      # config/shibboleth.xml.
      post "/auth/shibboleth/callback", env: {
        "omniauth.auth": {
          provider:          "shibboleth",
          "Shib-Session-ID": SecureRandom.hex,
          uid:               user.uid,
          info: {
            email: user.email
          },
          extra: {
            raw_info: {
              "org-dn":           user.org_dn,
              overwriteUserAttrs: "false"
            }
          }
        }
      }
    else
      post "/auth/identity/callback", params: {
        auth_key: user.email,
        password: "password"
      }
    end
  end

  def log_out
    delete logout_path
  end

  def clear_message_queue
    AmqpHelper::Connector[:ideals].clear_queues(Message.outgoing_queue)
  end

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

  ##
  # Creates the application S3 bucket (if it does not already exist) and
  # uploads objects to it corresponding to every [Bitstream].
  #
  def setup_s3
    client = S3Client.instance
    bucket = ::Configuration.instance.aws[:bucket]
    client.create_bucket(bucket: bucket) unless client.bucket_exists?(bucket)

    Bitstream.all.each do |bs|
      key = bs.permanent_key.present? ? bs.permanent_key : bs.staging_key
      client.put_object(bucket: bucket,
                        key:    key,
                        body:   file_fixture("escher_lego.jpg").to_s)
    end
  end

  def teardown_s3
    client = S3Client.instance
    bucket = ::Configuration.instance.aws[:bucket]
    client.delete_objects(bucket: bucket)
  end

end
