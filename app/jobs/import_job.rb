# frozen_string_literal: true

##
# Imports items from SAF or CSV package, or CSV file.
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
    import      = args[0][:import]
    submitter   = args[0][:user]
    keys        = import.object_keys
    root_keys   = keys.select{ |k| k.split("/").length == keys.map{ |kl| kl.split("/").length }.sort.first }.
                       map{ |k| k.split("/").last }
    import.task = Task.create!(name:        self.class.name,
                               institution: submitter&.institution,
                               user:        submitter,
                               started_at:  Time.now,
                               status_text: "Importing items")

    # Try to detect the import format.
    if keys.length == 1 && keys[0].split(".").last.downcase == "csv"
      import.task.update!(status_text: "Importing items from CSV file")
      CsvImporter.new.import_from_s3(import, submitter)
      Import::Format::CSV_FILE
    elsif root_keys.include?("content") || root_keys.include?("contents")
      import.task.update!(status_text: "Importing items from SAF package")
      SafImporter.new.import_from_s3(import)
      Import::Format::SAF
    elsif root_keys.find{ |k| k.downcase.end_with?(".csv") }
      import.task.update!(status_text: "Importing items from CSV package")
      CsvImporter.new.import_from_s3(import, submitter)
      Import::Format::CSV_PACKAGE
    else
      import.task.fail(detail: "Unable to detect the package format.")
    end
  end

end
