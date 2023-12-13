# frozen_string_literal: true

##
# A job that sleeps for a given length of time. This is used mainly for testing
# the job worker.
#
class SleepJob < ApplicationJob

  QUEUE = ApplicationJob::Queue::ADMIN

  queue_as QUEUE

  ##
  # Arguments:
  #
  # * `:duration`: Sleep duration in seconds
  # * `:task`
  #
  # @param args [Hash]
  #
  def perform(**args)
    duration = args[:duration].to_i
    self.task = args[:task]
    self.task&.update!(name:          self.class.name,
                       queue:         QUEUE,
                       job_id:        self.job_id,
                       started_at:    Time.now,
                       status:        Task::Status::RUNNING,
                       status_text:   "Sleeping for #{duration} seconds")
    # Use a transaction in order to test that the task updates don't happen
    # within it.
    ActiveRecord::Base.transaction do
      duration.times do |i|
        self.task&.update!(percent_complete: i / duration.to_f)
        sleep 1
      end
    end
  end

end
