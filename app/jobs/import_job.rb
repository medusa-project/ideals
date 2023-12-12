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
    self.task = import.task
    self.task&.update!(name:          self.class.name,
                       user:          submitter,
                       institution:   import.institution,
                       indeterminate: false,
                       queue:         QUEUE,
                       job_id:        self.job_id,
                       started_at:    Time.now)
    begin
      Importer.new.import(import, submitter)
    ensure
      import.delete_file
    end
  end

end
