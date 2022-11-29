class ZipItemsJob < ApplicationJob

  queue_as :public

  ##
  # Creates a zip file containing all of the files attached to all of the
  # given items and uploads it to the application bucket. The files within the
  # zip file are organized by item handle, with the handle prefix as the root
  # directory, and each item's handle suffix as a subdirectory within.
  #
  # To include bitstreams from only one item, use {ZipBitstreamsJob} instead.
  #
  # Upon completion, the given {Download} instance's {Download#filename}
  # attribute is updated to reflect its filename within the application bucket.
  #
  # @param args [Array] Array containing an array of integer item IDs at
  #                     position 0 and a {Download} instance at position 1.
  # @raises [ArgumentError]
  # @see ZipBitstreamsJob
  #
  def perform(*args)
    item_ids = args[0]
    download = args[1]
    filename = "items-#{SecureRandom.hex[0..15]}.zip"
    task     = Task.create!(name:          self.class.name,
                            download:      download,
                            institution:   download.institution,
                            indeterminate: false,
                            started_at:    Time.now,
                            status_text:   "Preparing a #{item_ids.count}-item zip file")
    begin
      ActiveRecord::Base.transaction do
        download.update!(filename: filename)
        Item.create_zip_file(item_ids: item_ids,
                             dest_key: download.object_key,
                             task:     task)
      end
    rescue => e
      task.fail(detail:    e.message,
                backtrace: e.backtrace)
    else
      task.succeed
    end
  end

end
