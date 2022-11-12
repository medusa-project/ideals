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
      import.task = Task.create!(name:        self.class.name,
                                 institution: submitter&.institution,
                                 started_at:  Time.now,
                                 status_text: "Importing items from CSV")
      import.save!
      CsvImporter.new.import_from_s3(import, submitter)
      Import::Kind::CSV
    else
      import.task = Task.create!(name:        self.class.name,
                                 institution: submitter&.institution,
                                 started_at:  Time.now,
                                 status_text: "Importing items from SAF package")
      import.save!
      SafImporter.new.import_from_s3(import)
      Import::Kind::SAF
    end
  end

end
