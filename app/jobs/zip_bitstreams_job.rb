# frozen_string_literal: true

class ZipBitstreamsJob < ApplicationJob

  QUEUE = ApplicationJob::Queue::PUBLIC

  queue_as QUEUE

  ##
  # Creates a zip file containing the given bitstreams and uploads it to the
  # application bucket. The bitstreams are placed in the root directory of the
  # zip file, so they should all be from one item to avoid naming conflicts. To
  # include bitstreams from multiple items, use {ZipItemsJob} instead.
  #
  # Upon completion, the given {Download} instance's {Download#filename}
  # attribute is updated to reflect the filename of the zip within the
  # application bucket.
  #
  # @param args [Hash] Hash with a `:bitstreams` key containing an array of
  #                    {Bitstream}s; a `:download` key pointing to a {Download}
  #                    instance; an `:item_id` key; a `:user` key, and a
  #                    `:task` key.
  # @see ZipItemsJob
  #
  def perform(**args)
    bitstreams  = args[:bitstreams]
    download    = args[:download]
    item_id     = args[:item_id]
    user        = args[:user]
    institution = nil
    if item_id
      filename    = "item-#{item_id}.zip"
      institution = Item.find(item_id).institution
    else
      filename = "#{SecureRandom.hex[0..15]}.zip"
    end
    self.task = args[:task]
    self.task&.update!(name:          self.class.name,
                       download:      download,
                       user:          user,
                       institution:   institution,
                       indeterminate: true,
                       queue:         QUEUE,
                       job_id:        self.job_id,
                       started_at:    Time.now,
                       status_text:   "Creating zip file")

    ActiveRecord::Base.transaction do
      download.update!(filename: filename)
      Bitstream.create_zip_file(bitstreams: bitstreams,
                                dest_key:   download.object_key,
                                item_id:    item_id,
                                task:       self.task)
    end
  end

end
