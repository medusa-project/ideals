# frozen_string_literal: true

##
# Encapsulates a Medusa ingest.
#
# Generally it is more convenient to use {Bitstream#ingest_into_medusa} or
# {Item#ingest_into_medusa} than to use this class directly.
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
# @see https://github.com/medusa-project/medusa-collection-registry/blob/master/README-amqp-accrual.md
#
class MedusaIngest < ApplicationRecord

  ##
  # @return [String]
  # @private
  #
  def self.outgoing_queue
    ::Configuration.instance.medusa[:outgoing_queue]
  end

  def send_message
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