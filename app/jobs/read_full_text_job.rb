# frozen_string_literal: true

class ReadFullTextJob < ApplicationJob

  LOGGER = CustomLogger.new(ReadFullTextJob)
  QUEUE  = ApplicationJob::Queue::ADMIN

  queue_as QUEUE

  ##
  # @param args [Hash] Hash with `:bitstream`, `:user`, and `:task` keys.
  #
  def perform(**args)
    bitstream = args[:bitstream]
    user      = args[:user]
    self.task = args[:task]
    self.task&.update!(name:          self.class.name,
                       user:          user,
                       institution:   bitstream.institution,
                       indeterminate: true,
                       queue:         QUEUE,
                       job_id:        self.job_id,
                       started_at:    Time.now,
                       status:        Task::Status::RUNNING,
                       status_text:   "Reading full text of #{bitstream.filename}")

    bitstream.read_full_text
  end

end
