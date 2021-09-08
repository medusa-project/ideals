##
# Handles incoming messages from Medusa.
#
# @see https://github.com/medusa-project/medusa-collection-registry/blob/master/README-amqp-accrual.md
#
class MessageHandler

  ##
  # Handles an incoming message from Medusa.
  #
  # @param message [String] JSON message string.
  #
  def self.handle(message)
    message_hash = JSON.parse(message)
    if MessageHandler.valid?(message_hash) && message_hash['status'] == "ok"
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
  # @param message_json [String] JSON-serialized message.
  # @param message_hash [Hash] Deserialized message.
  # @private
  #
  def self.on_delete_succeeded_message(message_json, message_hash)
    message = Message.find_by_medusa_uuid(message_hash['uuid'])
    message.update!(status:        Message::Status::OK,
                    raw_response:  message_json,
                    response_time: Time.now)
    # This should already be deleted, but just in case, we delete it rather
    # than destroying it in order to avoid callbacks, which could cause an
    # infinite loop.
    message.bitstream&.delete
  end

  ##
  # @param message_json [String] JSON-serialized message.
  # @param message_hash [Hash] Deserialized message.
  # @private
  #
  def self.on_delete_failed_message(message_json, message_hash)
    message = Message.find_by_medusa_uuid(message_hash['uuid'])
    message.update!(status:        message_hash['status'],
                    raw_response:  message_json,
                    response_time: Time.now)
    error_string = "Failed to delete from Medusa:\n\n#{message_hash.to_yaml}"
    IdealsMailer.error(error_string).deliver_now
  end

  ##
  # @param message_json [String] JSON-serialized message.
  # @param message_hash [Hash] Deserialized message.
  # @private
  #
  def self.on_ingest_succeeded_message(message_json, message_hash)
    message = Message.find_by_staging_key(message_hash['staging_key'])
    if message
      message.update!(status:        message_hash['status'],
                      medusa_key:    message_hash['medusa_key'],
                      medusa_uuid:   message_hash['uuid'],
                      response_time: Time.now,
                      raw_response:  message_json)
    else
      IdealsMailer.error("Outgoing message not found for staging key:"\
          "#{message_hash['staging_key']}\n\n Response:\n"\
          "#{message_hash.to_yaml}").deliver_now
      return false
    end

    bitstream = message.bitstream
    if bitstream
      bitstream.update!(medusa_uuid: message_hash['uuid'],
                        medusa_key:  message_hash['medusa_key'])
      # Now that it has been successfully ingested, delete it from staging.
      bitstream.delete_from_staging
    else
      IdealsMailer.error("Bitstream not found for message:\n\n"\
          "#{message_hash.to_yaml}").deliver_now
    end
  end

  ##
  # @param message_json [String] JSON-serialized message.
  # @param message_hash [Hash] Deserialized message.
  # @private
  #
  def self.on_ingest_failed_message(message_json, message_hash)
    message = Message.find_by_staging_key(message_hash['staging_key'])
    if message
      message.update!(status:        message_hash['status'],
                      error_text:    message_hash['error'],
                      response_time: Time.now,
                      raw_response:  message_json)
      IdealsMailer.error("Failed to ingest into Medusa:\n#{message_hash.to_yaml}").deliver_now
    else
      IdealsMailer.error("Outgoing message not found for staging key:"\
          "#{message_hash['staging_key']}\n\n Response:\n"\
          "#{message_hash.to_yaml}").deliver_now
      return false
    end
  end

end
