# frozen_string_literal: true

##
# Invokes an {Importer}.
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
    begin
      Importer.new.import(import, submitter)
    rescue => e
      import.task.fail(detail:    e.message,
                       backtrace: e.backtrace)
    end
  end

end
