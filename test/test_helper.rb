# frozen_string_literal: true

ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"

# The default reporter prints skipped & failing tests at the end of the output,
# so we don't have to scroll.
Minitest::Reporters.use! unless ENV['RM_INFO'].present?

class ActiveSupport::TestCase
  # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
  fixtures :all

  def self.seeding?
    @@seeding
  end

  def clear_message_queues
    Institution.
      where.not(outgoing_message_queue: nil).
      pluck(:outgoing_message_queue).each do |queue|
      AmqpHelper::Connector[:ideals].clear_queues(queue)
    end
  end

  ##
  # Seeded bitstreams have an invalid staging_key and/or permanent_key
  # property (because an item ID is needed to compute one). This method fixes
  # these properties.
  #
  def fix_bitstream_keys(bitstream)
    if bitstream.staging_key.present?
      staging_key = Bitstream.staging_key(
        institution_key: bitstream.institution.key,
        item_id:         bitstream.item_id,
        filename:        bitstream.filename)
      bitstream.update_column(:staging_key, staging_key)
    end
    if bitstream.permanent_key.present?
      permanent_key = Bitstream.permanent_key(
        institution_key: bitstream.institution.key,
        item_id:         bitstream.item_id,
        filename:        bitstream.filename)
      bitstream.update_column(:permanent_key, permanent_key)
    end
  end

  ##
  # @param user [User]
  # @param provider [Symbol] `:saml`, `:shibboleth`, or `:local`. If omitted,
  #                          and the user has an associated {LocalIdentity},
  #                          local is assumed; otherwise :shibboleth.
  #
  def log_in_as(user, provider = nil)
    unless provider
      if user.identity
        provider = :local
      elsif user.institution.key == "uiuc"
        provider = :shibboleth
      else
        provider = :saml
      end
    end
    case provider
    when :saml
      post "/auth/saml/callback", env: {
        "omniauth.auth": {
          provider:          "saml",
          uid:               user.email,
          info: {
            email: user.email
          },
          extra: {
            raw_info: OneLogin::RubySaml::Attributes.new(
              overwriteUserAttrs: "false",
              emailAddress: [user.email]
            )
          }
        }
      }
    when :shibboleth
      # N.B. 1: See "request_type option" section for info about using
      # omniauth-shibboleth in development:
      # https://github.com/toyokazu/omniauth-shibboleth
      #
      # N.B. 2: the keys in the auth hash must be present in
      # config/shibboleth.xml.
      post "/auth/shibboleth/callback", env: {
        "omniauth.auth": {
          provider:          "shibboleth",
          "Shib-Session-ID": SecureRandom.hex,
          uid:               user.email,
          info: {
            email: user.email
          },
          extra: {
            raw_info: {
              "org-dn":           user.institution.shibboleth_org_dn,
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

  def make_sysadmin(user)
    user.user_groups << user_groups(:sysadmin)
    user.save!
    user
  end

  def refresh_opensearch
    client = OpenSearchClient.instance
    client.refresh(Configuration.instance.opensearch[:index])
  end

  def setup_opensearch
    index = Configuration.instance.opensearch[:index]
    client = OpenSearchClient.instance
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
    client.put_bucket_policy(bucket: bucket,
                             policy: JSON.generate({
                                                     Version: "2012-10-17",
                                                     Statement: [
                                                       {
                                                         Principal: "*",
                                                         Effect: "Allow",
                                                         Action: [
                                                           "s3:GetObject"
                                                         ],
                                                         Resource: [
                                                           "arn:aws:s3:::#{bucket}/*"
                                                         ]
                                                       }
                                                     ]
                                                   }))
    client.delete_objects(bucket: bucket)

    @@seeding = true
    Bitstream.where("staging_key IS NOT NULL OR permanent_key IS NOT NULL").each do |bs|
      fix_bitstream_keys(bs)
      File.open(file_fixture(bs.original_filename), "r") do |file|
        PersistentStore.instance.put_object(key:  bs.effective_key,
                                            file: file)
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
