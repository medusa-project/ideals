# frozen_string_literal: true

##
# Encapsulates an outgoing and incoming Medusa AMQP message.
#
# N.B.: When working within a transaction, instances should be persisted using
# a separate database connection, like this:
#
# ```
# ActiveRecord::Base.connection_pool.with_connection { ... persistence code ... }
# ```
#
# The objective is to maintain an instance corresponding to each message sent
# to Medusa, but consider the case of e.g. an instance created inside a
# transaction that rolls back after a message has already been sent to the
# queue. Using a separate connection like this ensures persistence.
#
# # Attributes
#
# * `bitstream_id`   Foreign key to {Bitstream}. May be `nil` if the related
#                    bitstream has been deleted.
# * `created_at`     Managed by ActiveRecord.
# * `error_text`     Error text provided by a response message from Medusa.
# * `institution_id` Foreign key to {Institution}.
# * `medusa_key`     Key of the file in Medusa. This is set by a response
#                    message and should be the same as `target_key`.
# * `medusa_uuid`    UUID of the corresponding Medusa file.
# * `operation`      One of the {Message::Operation} constant values.
# * `response_time`  Arrival time of the response message from Medusa.
# * `sent_at`        Time the message was sent or resent.
# * `staging_key`    Key of the **permanent** (not staging) object in the
#                    application S3 bucket.
# * `status`         Set by a response message from Medusa to one of the
#                    {Message::Status} constant values.
# * `target_key`     Key of the target object in the Medusa S3 bucket.
# * `updated_at`     Managed by ActiveRecord.
#
# @see https://github.com/medusa-project/medusa-collection-registry/blob/master/README-amqp-accrual.md
#
class Message < ApplicationRecord

  class Operation
    DELETE = "delete"
    INGEST = "ingest"
  end

  class Status
    OK     = "ok"
    ERROR  = "error"
    RESENT = "resent"
  end

  belongs_to :bitstream, optional: true
  belongs_to :institution

  validates :operation, inclusion: { in: Operation.constants.map{ |c| Operation.const_get(c) },
                                     message: "%{value} is not a valid operation" }

  ##
  # @return [String] Console representation of the instance.
  #
  def as_console
    lines = ["#{self.id}----------------------------------"]
    lines << "Created:       #{self.created_at.localtime}"
    lines << "Updated:       #{self.updated_at.localtime}"
    lines << "Operation:     #{self.operation}"
    lines << "Item:          #{self.bitstream.item_id}"
    lines << "Bitstream:     #{self.bitstream_id}"
    lines << "Staging Key:   #{self.staging_key}"
    lines << "Target Key:    #{self.target_key}"
    lines << "Status:        #{self.status}"
    lines << "Response Time: #{self.response_time}"
    lines << "Medusa UUID:   #{self.medusa_uuid}"
    lines << "Error:         #{self.error_text}" if self.error_text.present?
    lines.join("\n")
  end

  def label
    "#{self.operation} @ #{self.created_at}"
  end

  ##
  # @return [String, nil]
  #
  def medusa_url
    self.medusa_uuid.present? ?
      "#{::Configuration.instance.medusa[:base_url]}/uuids/#{self.medusa_uuid}"
      : nil
  end

  ##
  # @see send_message
  #
  def resend
    update!(status:        Status::RESENT,
            error_text:    nil,
            response_time: nil)
    send_message
  end

  ##
  # @see resend
  #
  def send_message
    case self.operation
    when Operation::DELETE
      message = delete_message
    else
      message = ingest_message
    end
    queue = self.institution.outgoing_message_queue
    AmqpHelper::Connector[:ideals].send_message(queue, message)
    self.update!(sent_at: Time.now)
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