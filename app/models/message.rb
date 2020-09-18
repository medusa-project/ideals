# frozen_string_literal: true

##
# Encapsulates an outgoing and incoming Medusa AMQP message.
#
# # Attributes
#
# * `bitstream_id`  Foreign key to {Bitstream}. May be `nil` if the related
#                   bitstream has been deleted.
# * `created_at`    Managed by ActiveRecord.
# * `error_text`    Error text provided by a response message from Medusa.
# * `medusa_key`    Key of the file in Medusa. This is set by a response
#                   message and should be the same as `target_key`.
# * `medusa_uuid`   UUID of the corresponding Medusa file.
# * `operation`     One of the {Message::Operation} constant values.
# * `response_time` Arrival time of the response message from Medusa.
# * `staging_key`   Key of the staging object in the application S3 bucket.
# * `status`        Set by a response message from Medusa to one of the
#                   {Message::Status} constant values.
# * `target_key`    Key of the target object in the Medusa S3 bucket.
# * `updated_at`    Managed by ActiveRecord.
#
# @see https://github.com/medusa-project/medusa-collection-registry/blob/master/README-amqp-accrual.md
#
class Message < ApplicationRecord

  class Operation
    DELETE = "delete"
    INGEST = "ingest"
  end

  class Status
    OK    = "ok"
    ERROR = "error"
  end

  belongs_to :bitstream

  validates :operation, inclusion: { in: Operation.constants.map{ |c| Operation.const_get(c) },
                                     message: "%{value} is not a valid operation" }

  ##
  # @return [String] Name of the incoming message queue from the application
  #                  configuration.
  #
  def self.incoming_queue
    ::Configuration.instance.medusa[:incoming_queue]
  end

  ##
  # @return [String] Name of the outgoing message queue from the application
  #                  configuration.
  #
  def self.outgoing_queue
    ::Configuration.instance.medusa[:outgoing_queue]
  end

  def resend
    update!(status:         "resent",
            error_text:     nil,
            response_time:  nil)
    send
  end

  def send_message
    case self.operation
    when Operation::DELETE
      message = delete_message
    else
      message = ingest_message
    end
    AmqpHelper::Connector[:ideals].send_message(self.class.outgoing_queue,
                                                message)
  end


  private

  ##
  # @return [Hash]
  #
  def delete_message
    {
        operation: Operation::DELETE,
        uuid:      self.medusa_uuid,
        pass_through: {
            class:      Bitstream.to_s,
            identifier: self.bitstream_id
        }
    }
  end

  ##
  # @return [Hash]
  #
  def ingest_message
    {
        operation:    Operation::INGEST,
        staging_key:  self.staging_key,
        target_key:   self.target_key,
        pass_through: {
            class:      Bitstream.to_s,
            identifier: self.bitstream_id
        }
    }
  end

end