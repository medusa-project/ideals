# frozen_string_literal: true

class UploadFaviconsJob < ApplicationJob

  QUEUE = ApplicationJob::Queue::ADMIN

  queue_as QUEUE

  ##
  # @param args [Hash] Hash with `:master_favicon_path`, `:institution`, and
  #                    `:user` keys.
  # @raises [ArgumentError]
  #
  def perform(**args)
    tempfile    = args[:master_favicon_path]
    institution = args[:institution]

    self.task&.update!(status_text: "Processing favicons")
    begin
      File.open(tempfile, "r") do |file|
        institution.upload_favicon(io: file, task: task)
      end
    ensure
      File.delete(tempfile)
    end
  end

end
