# frozen_string_literal: true

##
# Invokes an {Importer}.
#
class ImportJob < ApplicationJob

  LOGGER = CustomLogger.new(ImportJob)
  QUEUE  = ApplicationJob::Queue::ADMIN

  queue_as QUEUE

  ##
  # @param args [Hash] Hash with `:import` and `:user` keys.
  # @return [Integer] One of the {Import::Format} constant values, used for
  #                   testing.
  # @raises [ArgumentError]
  #
  def perform(**args)
    import    = args[:import]
    submitter = args[:user]
    # This job is a little different in that we want to share the Import's Task
    # rather than allowing the superclass to create one.
    self.task = import.task
    begin
      Importer.new.import(import, submitter)
    ensure
      import.delete_file
    end
  end

end
