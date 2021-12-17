class ImportSafPackageJob < ApplicationJob

  LOGGER = CustomLogger.new(ImportSafPackageJob)

  queue_as :admin

  ##
  # @param args [Array] One-element array containing an [Import] instance.
  # @raises [ArgumentError]
  #
  def perform(*args)
    # Files to import have just been uploaded to S3. S3 is only eventually
    # consistent, so we want to give it time for all of them to show up.
    sleep 2
    SafImporter.new.import_from_s3(args[0])
  end

end
