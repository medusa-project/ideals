# frozen_string_literal: true

class ReadFullTextJob < ApplicationJob

  LOGGER = CustomLogger.new(ReadFullTextJob)

  queue_as :admin

  ##
  # @param args [Array<Hash>] One-element array containing a Hash with
  #                           `:bitstream` and `:user` keys.
  #
  def perform(*args)
    bitstream   = args[0][:bitstream]
    user        = args[0][:user]
    institution = bitstream.institution
    task        = Task.create!(name:          self.class.name,
                               institution:   institution,
                               user:          user,
                               indeterminate: true,
                               status_text:   "Reading full text of #{bitstream.filename}")
    begin
      bitstream.read_full_text
    rescue => e
      task.fail(detail:    e.message,
                backtrace: e.backtrace)
    else
      task.succeed
    end
  end

end
