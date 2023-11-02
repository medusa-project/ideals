# frozen_string_literal: true

class RefreshOpensearchJob < ApplicationJob

  QUEUE = ApplicationJob::Queue::ADMIN

  queue_as QUEUE

  def has_task?
    false
  end

  ##
  # @param args [Hash] Empty hash.
  #
  def perform(**args)
    OpenSearchClient.instance.refresh
  end

end
