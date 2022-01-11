class ImportSafPackageJob < ApplicationJob

  LOGGER = CustomLogger.new(ImportSafPackageJob)

  queue_as :admin

  ##
  # @param args [Array] One-element array containing an [Import] instance.
  # @raises [ArgumentError]
  #
  def perform(*args)
    SafImporter.new.import_from_s3(args[0])
  end

end
