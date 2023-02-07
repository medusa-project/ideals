class RefreshOpensearchJob < ApplicationJob

  queue_as :admin

  ##
  # @param args [Array] Zero-element array.
  #
  def perform(*args)
    OpenSearchClient.instance.refresh
  end

end
