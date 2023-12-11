# frozen_string_literal: true

class ZipItemsJob < ApplicationJob

  QUEUE = ApplicationJob::Queue::PUBLIC

  queue_as QUEUE

  ##
  # Creates a zip file containing all of the files attached to all of the given
  # items and uploads it to the application bucket.
  #
  # To include bitstreams from only one item, use {ZipBitstreamsJob} instead.
  #
  # Upon completion, the given {Download} instance's {Download#filename}
  # attribute is updated to reflect its filename within the application bucket.
  #
  # @param args [Hash] Hash with `:item_ids`, `:metadata_profile`, `:download`,
  #                    and `:user` keys.
  # @see ZipBitstreamsJob
  #
  def perform(**args)
    item_ids         = args[:item_ids]
    metadata_profile = args[:metadata_profile]
    download         = args[:download]
    filename         = "items-#{SecureRandom.hex[0..15]}.zip"

    self.task&.update!(download:    download,
                       institution: download.institution,
                       started_at:  Time.now,
                       status_text: "Preparing a #{item_ids.count}-item zip file")
    ActiveRecord::Base.transaction do
      download.update!(filename: filename)
      Item.create_zip_file(item_ids:         item_ids,
                           metadata_profile: metadata_profile,
                           dest_key:         download.object_key,
                           task:             self.task)
    end
  end

end
