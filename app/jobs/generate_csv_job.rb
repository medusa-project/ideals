# frozen_string_literal: true

class GenerateCsvJob < ApplicationJob

  QUEUE = ApplicationJob::Queue::PUBLIC

  queue_as QUEUE

  ##
  # Generates a CSV file for a collection and uploads it to the application
  # bucket.
  #
  # Upon completion, the given {Download} instance's {Download#filename}
  # attribute is updated to reflect its filename within the application bucket.
  #
  # @param args [Hash] Hash with `:collection` (or `:unit`), `:download`,
  #                    `:user`, and `:task` keys.
  #
  def perform(**args)
    collection = args[:collection]
    unit       = args[:unit]
    download   = args[:download]
    user       = args[:user]
    self.task  = args[:task]
    self.task&.update!(name:          self.class.name,
                       download:      download,
                       user:          user,
                       institution:   download.institution,
                       indeterminate: true,
                       queue:         QUEUE,
                       job_id:        self.job_id,
                       started_at:    Time.now,
                       status:        Task::Status::RUNNING,
                       status_text:   "Generating CSV for #{(collection || unit).title}")

    exporter = CsvExporter.new
    if collection
      csv = exporter.export_collection(collection)
      download.update!(filename: "collection_#{collection.id}_items.csv")
    else
      csv = exporter.export_unit(unit)
      download.update!(filename: "unit_#{unit.id}_items.csv")
    end
    ObjectStore.instance.put_object(key:  download.object_key,
                                    data: csv)
  end

end
