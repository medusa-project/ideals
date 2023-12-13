# frozen_string_literal: true

class GenerateDerivativeImageJob < ApplicationJob

  # This job needs to run sequentially because it may ultimately invoke
  # `soffice` which will hang both itself and the job (blocking the queue) if
  # there is another `soffice` process running. We don't know for sure that
  # it's going to run `soffice` (it only will for Office formats) but there is
  # no way to tell at this point.
  QUEUE = ApplicationJob::Queue::PUBLIC_SEQUENTIAL

  queue_as QUEUE

  ##
  # @param args [Hash] Hash with `:bitstream`, `:region`, `:size`, `:format`,
  #                    and `:task` keys.
  #
  def perform(**args)
    bs        = args[:bitstream]
    region    = args[:region]
    size      = args[:size]
    format    = args[:format]
    self.task = args[:task]

    self.task&.update!(name:          self.class.name,
                       institution:   bs.institution,
                       indeterminate: true,
                       queue:         QUEUE,
                       job_id:        self.job_id,
                       started_at:    Time.now,
                       status:        Task::Status::RUNNING,
                       status_text:   "Generating #{region}/#{size} #{format} "\
                                      "derivative image for #{bs.filename} "\
                                      "[item ID #{bs.item_id}] [bitstream ID #{bs.id}]")

    DerivativeGenerator.new(bs).generate_image_derivative(region: region,
                                                          size:   size,
                                                          format: format)
  end

end
