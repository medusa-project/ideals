##
# A job that sleeps for a given length of time. This is used mainly for testing
# the job worker.
#
class SleepJob < ApplicationJob

  queue_as :admin

  ##
  # Arguments:
  #
  # * `:duration`: Sleep duration in seconds
  #
  # @param args [Hash]
  #
  def perform(*args)
    duration = args[0][:duration].to_i
    task     = Task.create!(name:          self.class.name,
                            indeterminate: false,
                            started_at:    Time.now,
                            status_text:   "Sleeping for #{duration} seconds")
    duration.times do |i|
      task.update!(percent_complete: i / duration.to_f)
      sleep 1
    end
    task.succeed
  end

end
