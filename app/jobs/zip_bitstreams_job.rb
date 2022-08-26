class ZipBitstreamsJob < ApplicationJob

  queue_as :public

  ##
  # Creates a zip file containing the given bitstreams and uploads it to the
  # application bucket. The given [Download] instance's {Download#filename}
  # attribute is updated to reflect its filename within the bucket.
  #
  # @param args [Array] Array containing an array of [Bitstream]s at position
  #                     0, a [Download] instance at position 1, and, optionally,
  #                     an [Item] ID integer at position 2.
  # @raises [ArgumentError]
  #
  def perform(*args)
    bitstreams = args[0]
    download   = args[1]
    item_id    = args[2]
    if item_id
      filename = "item-#{item_id}.zip"
    else
      filename = "#{SecureRandom.hex[0..15]}.zip"
    end
    dest_key   = "#{Download::DOWNLOADS_KEY_PREFIX}#{filename}"
    task       = Task.create!(name:          self.class.name,
                              download:      download,
                              indeterminate: false,
                              started_at:    Time.now,
                              status_text:   "Creating zip file")
    begin
      Bitstream.create_zip_file(bitstreams: bitstreams,
                                dest_key:   dest_key,
                                item_id:    item_id,
                                task:       task)
      download.update!(filename: filename)
    rescue => e
      task.fail(detail:    e.message,
                backtrace: e.backtrace)
    else
      task.succeed
    end
  end

end