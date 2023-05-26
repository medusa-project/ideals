# frozen_string_literal: true

##
# Imports items from SAF package or CSV file.
#
class ImportJob < ApplicationJob

  LOGGER = CustomLogger.new(ImportJob)

  queue_as :admin

  ##
  # @param args [Array<Hash>] One-element array containing a Hash with
  #                           `:import` and `:user` keys.
  # @return [Integer] One of the {Import::Format} constant values, used for
  #                   testing.
  # @raises [ArgumentError]
  #
  def perform(*args)
    import    = args[0][:import]
    submitter = args[0][:user]
    keys      = import.object_keys

    # Try to detect the import format.
    if keys.length == 1 && keys[0].split(".").last.downcase == "csv"
      import.task = Task.create!(name:        self.class.name,
                                 institution: submitter&.institution,
                                 user:        submitter,
                                 started_at:  Time.now,
                                 status_text: "Importing items from CSV")
      import.save!
      CsvImporter.new.import_from_s3(import, submitter)
      Import::Format::CSV_FILE
    else
      import.task = Task.create!(name:        self.class.name,
                                 institution: submitter&.institution,
                                 user:        submitter,
                                 started_at:  Time.now,
                                 status_text: "Importing items from SAF package")
      import.save!
      SafImporter.new.import_from_s3(import)
      Import::Format::SAF
    end
  end

end
