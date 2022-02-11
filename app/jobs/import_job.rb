##
# Imports items from SAF package or CSV file.
#
class ImportJob < ApplicationJob

  LOGGER = CustomLogger.new(ImportJob)

  queue_as :admin

  ##
  # @param args [Array] Two-element array with [Import] instance at position 0
  #                     and [User] instance at position 1.
  # @return [Integer] One of the [Import::Kind] constant values, used for
  #                   testing.
  # @raises [ArgumentError]
  #
  def perform(*args)
    import    = args[0]
    submitter = args[1]
    keys      = import.object_keys
    if keys.length == 1 && keys[0].split(".").last.downcase == "csv"
      CsvImporter.new.import_from_s3(import, submitter)
      Import::Kind::CSV
    else
      SafImporter.new.import_from_s3(import)
      Import::Kind::SAF
    end
  end

end
