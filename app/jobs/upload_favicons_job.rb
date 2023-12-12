# frozen_string_literal: true

class UploadFaviconsJob < ApplicationJob

  QUEUE = ApplicationJob::Queue::ADMIN

  queue_as QUEUE

  ##
  # @param args [Hash] Hash with `:master_favicon_path`, `:institution`,
  #                    `:user`, and `:task` keys.
  # @raises [ArgumentError]
  #
  def perform(**args)
    tempfile    = args[:master_favicon_path]
    institution = args[:institution]
    user        = args[:user]
    self.task   = args[:task]
    self.task&.update!(name:          self.class.name,
                       user:          user,
                       institution:   institution,
                       indeterminate: true,
                       queue:         QUEUE,
                       job_id:        self.job_id,
                       started_at:    Time.now,
                       status_text:   "Processing favicons")
    begin
      File.open(tempfile, "r") do |file|
        institution.upload_favicon(io: file, task: task)
      end
    ensure
      File.delete(tempfile)
    end
  end

end
