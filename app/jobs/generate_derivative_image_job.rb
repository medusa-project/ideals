# frozen_string_literal: true

class GenerateDerivativeImageJob < ApplicationJob

  QUEUE = ApplicationJob::Queue::PUBLIC

  queue_as QUEUE

  ##
  # @param args [Hash] Hash with `:bitstream`, `:region`, `:size`, and
  #                    `:format` keys.
  #
  def perform(**args)
    bs     = args[:bitstream]
    region = args[:region]
    size   = args[:size]
    format = args[:format]

    self.task&.update!(indeterminate: true,
                       status_text:   "Generating #{region}/#{size} #{format} "\
                                      "derivative image for #{bs.filename} "\
                                      "(item ID #{bs.item_id})")
    Timeout::timeout(60) do
      bs.send(:generate_image_derivative,
              region: region, size: size, format: format)
    end
  rescue Timeout::Error => e
    bs.update!(known_derivative_error: true)
    throw e
  end

end
