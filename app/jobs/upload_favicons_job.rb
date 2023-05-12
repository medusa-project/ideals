# frozen_string_literal: true

class UploadFaviconsJob < ApplicationJob

  queue_as :admin

  ##
  # @param args [Array<Hash>] One-element array containing a hash. The hash
  #                           has `:master_favicon_path`, `:institution`, and
  #                           `:user` keys.
  # @raises [ArgumentError]
  #
  def perform(*args)
    tempfile    = args[0][:master_favicon_path]
    institution = args[0][:institution]
    user        = args[0][:user]
    task        = Task.create!(name:          self.class.name,
                               institution:   institution,
                               user:          user,
                               indeterminate: false,
                               started_at:    Time.now,
                               status_text:   "Processing favicons")
    begin
      File.open(tempfile, "r") do |file|
        institution.upload_favicon(io: file, task: task)
      end
    rescue => e
      task.fail(detail:    e.message,
                backtrace: e.backtrace)
    else
      task.succeed
    ensure
      File.delete(tempfile)
    end
  end

end
