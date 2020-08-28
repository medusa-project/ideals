# frozen_string_literal: true

##
# This code forked from: https://github.com/medusa-project/databank/blob/489cd6238ac1c35178cd237d8f0fc428ff1bd0a5/app/models/medusa_ingest.rb
#
# # Example Usage
#
# ```
# MedusaIngest.send_item_bitstreams_to_medusa(item)
# ```
#
# # Attributes
#
# * `created_at`        Managed by ActiveRecord.
# * `error_text`
# * `ideals_class`
# * `ideals_identifier` Unique identifier of the instance of `ideals_class`
#                       (typically a database ID).
# * `medusa_path`       Path a.k.a. key of the file in Medusa.
# * `medusa_uuid`       UUID of the corresponding Medusa file.
# * `request_status`    Set by a response message from Medusa.
# * `response_time`     Arrival time of the response message from Medusa.
# * `staging_key`       Key of the staging object in the application S3 bucket.
# * `target_key`        Key of the target object in the Medusa S3 bucket.
# * `updated_at`        Managed by ActiveRecord.
#
class MedusaIngest < ApplicationRecord

  ##
  # @return [String]
  # @private
  #
  def self.incoming_queue
    ::Configuration.instance.medusa[:incoming_queue]
  end

  ##
  # @param response_hash [Hash] Deserialized JSON.
  # @private
  #
  def self.message_valid?(response_hash)
    if %w[ok error].include?(response_hash['status'])
      true
    else
      IdealsMailer.error("Invalid message: #{response_hash['status']}").deliver_now
      false
    end
  end

  def self.on_medusa_message(response)
    response_hash = JSON.parse(response)
    if MedusaIngest.message_valid?(response_hash) && response_hash['status'] == "ok"
      ingest_response = IngestResponse.new(status:        "ok",
                                           response_time: Time.current.iso8601,
                                           staging_key:   response_hash['staging_key'],
                                           medusa_key:    response_hash['medusa_key'],
                                           uuid:          response_hash['uuid'])
      ingest_response.as_text = response
      ingest_response.save!
      on_medusa_succeeded_message(response_hash)
    else
      IngestResponse.create!(as_text: response,
                             status:  response_hash['status'])
      on_medusa_failed_message(response_hash)
    end
  end

  ##
  # @private
  #
  def self.on_medusa_succeeded_message(response_hash)
    ingests = MedusaIngest.
        where(staging_key: response_hash['staging_key']).
        order(:updated_at)
    ingest = ingests.first
    if ingests.count > 0
      ingests.where.not(id: ingest.id).destroy_all
    else
      IdealsMailer.error("Ingest not found. #{response_hash['pass_through']}: "\
          "#{response_hash.to_yaml}").deliver_now
      return false
    end

    # Update ingest record to reflect the response
    ingest.update!(medusa_path:    response_hash['medusa_key'],
                   medusa_uuid:    response_hash['uuid'],
                   response_time:  Time.now.utc.iso8601,
                   request_status: response_hash['status'])

    file_class = response_hash['pass_through']['class']

    if file_class == Bitstream.to_s
      bitstream = Bitstream.find_by(id: response_hash['pass_through']['identifier'])
      if bitstream
        bitstream.update!(medusa_uuid: response_hash['uuid'],
                          medusa_key:  response_hash['medusa_key'])
        # Now that it has been successfully ingested, delete it from staging.
        bitstream.delete_from_staging
      else
        IdealsMailer.error("Bitstream not found for ingest-succeeded "\
            "message from Medusa: #{response_hash.to_yaml}").deliver_now
      end
    end
  end

  ##
  # @private
  #
  def self.on_medusa_failed_message(response_hash)
    error_string = "Failed to ingest into Medusa:\n\n#{response_hash.to_yaml}"
    ingests      = MedusaIngest.where(staging_key: response_hash["staging_key"])
    if ingests.any?
      ingest = ingests.first
      ingest.update!(request_status: response_hash['status'],
                     error_text:     response_hash['error'],
                     response_time:  Time.current.iso8601)
    else
      error_string += "\n\nCould not find file for Medusa failure message: "\
          "#{response_hash['staging_key']}"
    end
    IdealsMailer.error(error_string).deliver_now
  end

  ##
  # @return [String]
  # @private
  #
  def self.outgoing_queue
    ::Configuration.instance.medusa[:outgoing_queue]
  end

  def send_medusa_ingest_message
    AmqpHelper::Connector[:ideals].send_message(self.class.outgoing_queue,
                                                medusa_ingest_message)
  end


  private

  ##
  # @return [Hash]
  #
  def medusa_ingest_message
    {
        operation:    "ingest",
        staging_key:  staging_key,
        target_key:   target_key,
        pass_through: {
            class:      ideals_class,
            identifier: ideals_identifier
        }
    }
  end

end