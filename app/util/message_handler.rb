##
# Handles incoming messages from Medusa.
#
# @see https://github.com/medusa-project/medusa-collection-registry/blob/master/README-amqp-accrual.md
#
class MessageHandler

  LOGGER = CustomLogger.new(MessageHandler)

  ##
  # Handles an incoming message from Medusa.
  #
  # @param message [String] JSON message string.
  #
  def self.handle(message)
    message_hash = JSON.parse(message)
    if message_hash['status'] == "ok"
      case message_hash['operation']
      when "ingest"
        on_ingest_succeeded_message(message, message_hash)
      when "delete"
        on_delete_succeeded_message(message, message_hash)
      else
        raise "Invalid message from Medusa:\n\n"\
              "#{message_hash.to_yaml}"
      end
    else
      case message_hash['operation']
      when "ingest"
        on_ingest_failed_message(message, message_hash)
      when "delete"
        on_delete_failed_message(message, message_hash)
      else
        raise "Invalid message from Medusa:\n\n"\
              "#{message_hash.to_yaml}"
      end
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
    # We don't want to literally delete the bitstream, as it may have only been
    # deleted from Medusa and not the application. However, if it does still
    # exist, we do want to nil out its Medusa storage properties.
    message.bitstream&.update!(medusa_uuid: nil, medusa_key: nil)
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
    raise "Failed to delete from Medusa:\n\n#{message_hash.to_yaml}"
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
                      error_text:    nil,
                      response_time: Time.now,
                      raw_response:  message_json)
    else
      # The first two possibilities are not a problem and the third we can do
      # nothing about
      LOGGER.warn("Received an ingest-failed message for staging key: %s,"\
                  "but an outgoing message object was not found.\n\n"\
                  "Response: %s",
                  message_hash['staging_key'], message_hash.to_yaml)
    end

    bitstream = message.bitstream
    if bitstream
      bitstream.update!(medusa_uuid: message_hash['uuid'],
                        medusa_key:  message_hash['medusa_key'])
      # Now that it has been successfully ingested, delete it from staging.
      bitstream.delete_from_staging
    else
      raise "Bitstream not found for message:\n\n"\
            "#{message_hash.to_yaml}"
    end
  end

  ##
  # An ingest may fail for one of three reasons:
  #
  # 1. A file already exists at the target path.
  # 2. A file is already scheduled for ingestion.
  # 3. The staging key in the sent message was blank.
  #
  # Only #3 is really an error as far as IDEALS is concerned, but there is no
  # way to disambiguate these by the message alone.
  #
  # TODO: it would be useful to have Medusa return distinct errors for these different scenarios
  #
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
    else
      # The first two possibilities are not a problem and the third we can do
      # nothing about
      LOGGER.warn("Received an ingest-failed message for staging key: %s,"\
                  "but an outgoing message object was not found.\n\n"\
                  "Response: %s",
                  message_hash['staging_key'], message_hash.to_yaml)
    end
  end

end
