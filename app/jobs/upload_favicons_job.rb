class UploadFaviconsJob < ApplicationJob

  queue_as :admin

  ##
  # @param args [Array] Full path of the "master" favicon at position 0, and an
  #                     {Institution} instance at position 1.
  # @raises [ArgumentError]
  #
  def perform(*args)
    tempfile    = args[0]
    institution = args[1]
    task        = Task.create!(name:          self.class.name,
                               institution:   institution,
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
