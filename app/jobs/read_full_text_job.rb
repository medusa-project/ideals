# frozen_string_literal: true

class ReadFullTextJob < ApplicationJob

  LOGGER = CustomLogger.new(ReadFullTextJob)
  QUEUE  = ApplicationJob::Queue::ADMIN

  queue_as QUEUE

  ##
  # @param args [Hash] Hash with `:bitstream` and `:user` keys.
  #
  def perform(**args)
    bitstream = args[:bitstream]

    self.task&.update!(institution:   bitstream.institution,
                       indeterminate: true,
                       status_text:   "Reading full text of #{bitstream.filename}")

    bitstream.read_full_text
  end

end
