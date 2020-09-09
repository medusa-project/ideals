##
# Incoming message from Medusa.
#
# # Attributes
#
# `as_text`     Raw message.
# `created_at`  Managed by ActiveRecord.
# `medusa_key`  Medusa key of the file to which the message relates.
# `staging_key` Staging key of the file to which the message relates.
# `status`      Status of the operation to which the message relates; typically
#               `ok` or `error`.
# `uuid`        UUID of the Medusa entity to which the message relates.
# `updated_at`  Managed by ActiveRecord.
#
# @see https://github.com/medusa-project/medusa-collection-registry/blob/master/README-amqp-accrual.md
#
class IncomingMessage < ApplicationRecord

  ##
  # Handles an incoming message from Medusa.
  #
  # @param message [String] JSON message string.
  #
  def self.handle(message)
    message_hash = JSON.parse(message)
    if IncomingMessage.valid?(message_hash) && message_hash['status'] == "ok"
      if message_hash['operation'] == "delete"
        on_delete_succeeded_message(message, message_hash)
      else
        on_ingest_succeeded_message(message, message_hash)
      end
    else
      if message_hash['operation'] == "delete"
        on_delete_failed_message(message, message_hash)
      else
        on_ingest_failed_message(message, message_hash)
      end
    end
  end

  ##
  # @param message_hash [Hash] Deserialized JSON.
  # @return [Boolean]
  # @private
  #
  def self.valid?(message_hash)
    if %w[ok error].include?(message_hash['status']) &&
        %w[ingest delete].include?(message_hash['operation'])
      true
    else
      IdealsMailer.error("Invalid message from Medusa:\n\n"\
          "#{message_hash.to_yaml}").deliver_now
      false
    end
  end


  private

  ##
  # @param message [String] JSON-serialized message.
  # @param message_hash [Hash] Deserialized message.
  # @private
  #
  def self.on_delete_succeeded_message(message, message_hash)
    IncomingMessage.create!(status:  "ok",
                            uuid:    message_hash['uuid'],
                            as_text: message)
    bitstream = Bitstream.find_by_medusa_uuid(message_hash['uuid'])
    if bitstream
      # We should never arrive here, but given that we have, we delete the
      # bitstream rather than destroying it in order to avoid callbacks, which
      # could cause an infinite loop.
      bitstream.delete
    end
  end

  ##
  # @param message [String] JSON-serialized message.
  # @param message_hash [Hash] Deserialized message.
  # @private
  #
  def self.on_delete_failed_message(message, message_hash)
    IncomingMessage.create!(uuid:    message_hash['uuid'],
                            status:  message_hash['status'],
                            as_text: message)
    error_string = "Failed to delete from Medusa:\n\n#{message_hash.to_yaml}"
    IdealsMailer.error(error_string).deliver_now
  end

  ##
  # @param message [String] JSON-serialized message.
  # @param message_hash [Hash] Deserialized message.
  # @private
  #
  def self.on_ingest_succeeded_message(message, message_hash)
    IncomingMessage.create!(status:      "ok",
                            staging_key: message_hash['staging_key'],
                            medusa_key:  message_hash['medusa_key'],
                            uuid:        message_hash['uuid'],
                            as_text:     message)
    ingests = MedusaIngest.
        where(staging_key: message_hash['staging_key']).
        order(:updated_at)
    ingest = ingests.first
    if ingests.count > 0
      ingests.where.not(id: ingest.id).destroy_all
    else
      IdealsMailer.error("Ingest not found. #{message_hash['pass_through']}: "\
          "#{message_hash.to_yaml}").deliver_now
      return false
    end

    # Update ingest record to reflect the response
    ingest.update!(medusa_path:    message_hash['medusa_key'],
                   medusa_uuid:    message_hash['uuid'],
                   response_time:  Time.now.utc.iso8601,
                   request_status: message_hash['status'])

    file_class = message_hash['pass_through']['class']

    if file_class == Bitstream.to_s
      bitstream = Bitstream.find_by(id: message_hash['pass_through']['identifier'])
      if bitstream
        bitstream.update!(medusa_uuid: message_hash['uuid'],
                          medusa_key:  message_hash['medusa_key'])
        # Now that it has been successfully ingested, delete it from staging.
        bitstream.delete_from_staging
      else
        IdealsMailer.error("Bitstream not found for ingest-succeeded "\
            "message from Medusa: #{message_hash.to_yaml}").deliver_now
      end
    else
      # This should never happen.
      IdealsMailer.error("Unrecognized class: #{file_class}").deliver_now
    end
  end

  ##
  # @param message [String] JSON-serialized message.
  # @param message_hash [Hash] Deserialized message.
  # @private
  #
  def self.on_ingest_failed_message(message, message_hash)
    IncomingMessage.create!(uuid:        message_hash['uuid'],
                            status:      message_hash['status'],
                            staging_key: message_hash['staging_key'],
                            as_text:     message)
    error_string = "Failed to ingest into Medusa:\n\n#{message_hash.to_yaml}"
    ingests      = MedusaIngest.where(staging_key: message_hash["staging_key"])
    if ingests.any?
      ingest = ingests.first
      ingest.update!(request_status: message_hash['status'],
                     error_text:     message_hash['error'],
                     response_time:  Time.current.iso8601)
    else
      error_string += "\n\nCould not find file for Medusa failure message: "\
          "#{message_hash['staging_key']}"
    end
    IdealsMailer.error(error_string).deliver_now
  end

end
