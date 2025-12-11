# frozen_string_literal: true

class ZipCollectionJob < ApplicationJob

  QUEUE = ApplicationJob::Queue::PUBLIC

  queue_as QUEUE

  ##
  # Creates a zip file containing all of the files attached to all items in a
  # collection and uploads it to the application bucket.
  #
  # Upon completion, the given {Download} instance's {Download#filename}
  # attribute is updated to reflect its filename within the application bucket.
  #
  # @param args [Hash] Hash with `:collection`, `:download`, `:user`,
  #                    `:request_context`, and `:task` keys.
  # @see ZipItemsJob
  #
  def perform(**args)
    collection       = args[:collection]
    download         = args[:download]
    user             = args[:user]
    request_context  = args[:request_context]
    self.task        = args[:task]
    self.task&.update!(name:          self.class.name,
                       download:      download,
                       user:          user,
                       institution:   download.institution,
                       indeterminate: true,
                       queue:         QUEUE,
                       job_id:        self.job_id,
                       started_at:    Time.now,
                       status:        Task::Status::RUNNING,
                       status_text:   "Compiling a list of all items in #{collection.title}")

    filename = "collection_#{collection.id}_#{SecureRandom.hex[0..15]}.zip"

    # Include all child collections.
    collection_ids = [collection.id] + collection.all_child_ids
    # Compile a list of all item IDs to be added to the zip file.
    item_ids       = []
    relation       = Item.search.filter(Item::IndexFields::COLLECTIONS, collection_ids)
    ItemPolicy::Scope.new(request_context, relation).resolve.each_id_in_batches do |result|
      item_ids << result[:id]
    end

    self.task&.update!(status_text: "Preparing a zip file containing all "\
                                    "items in #{collection.title}")

    ActiveRecord::Base.transaction do
      download.update!(filename: filename)
      Item.create_zip_file(item_ids:         item_ids,
                           metadata_profile: collection.effective_metadata_profile,
                           dest_key:         download.object_key,
                           request_context:  request_context,
                           task:             self.task)
    end
  end

end
