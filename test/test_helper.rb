# frozen_string_literal: true

ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"

if ENV["CI"] == "1"
  require "minitest/reporters"
  Minitest::Reporters.use!
  Minitest::Reporters.use! Minitest::Reporters::SpecReporter.new
end

class ActiveSupport::TestCase
  # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
  fixtures :all

  def self.seeding?
    @@seeding
  end

  ##
  # Seeded bitstreams have an invalid staging_key and/or permanent_key
  # property (because an item ID is needed to compute one). This method fixes
  # these properties.
  #
  def fix_bitstream_keys(bitstream)
    submitted_for_ingest = bitstream.submitted_for_ingest
    if bitstream.staging_key.present?
      bitstream.staging_key = Bitstream.staging_key(bitstream.item_id,
                                                    bitstream.original_filename)
    end
    if bitstream.permanent_key.present?
      bitstream.permanent_key = Bitstream.permanent_key(bitstream.item_id,
                                                        bitstream.original_filename)
    end
    bitstream.save!
    # Restore submitted_for_ingest to its initial value
    bitstream.update_column(:submitted_for_ingest, submitted_for_ingest)
  end

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
    bucket = ::Configuration.instance.storage[:bucket]
    client.create_bucket(bucket: bucket) unless client.bucket_exists?(bucket)

    @@seeding = true
    Bitstream.where("staging_key IS NOT NULL OR permanent_key IS NOT NULL").each do |bs|
      fix_bitstream_keys(bs)
      File.open(file_fixture(bs.original_filename), "r") do |file|
        client.put_object(bucket: bucket,
                          key:    bs.effective_key,
                          body:   file)
      end
    end
    @@seeding = false
  end

  def teardown_s3
    client = S3Client.instance
    bucket = ::Configuration.instance.storage[:bucket]
    client.delete_objects(bucket: bucket)
  end

end
