class ReadFullTextJob < ApplicationJob

  LOGGER = CustomLogger.new(ReadFullTextJob)

  queue_as :admin

  ##
  # @param args [Array] One-element array containing a [Bitstream] instance.
  # @raises [ArgumentError]
  #
  def perform(*args)
    args[0].read_full_text
  end

end
