class GenerateDerivativeImageJob < ApplicationJob

  queue_as :public

  ##
  # @param args [Array] Four-element array with [Bitstream] at position 0 and
  #                     region, size, and format elements in the remaining
  #                     positions in the same format as the arguments to
  #                     {Bitstream#generate_derivative}.
  #
  def perform(*args)
    bs     = args[0]
    region = args[1]
    size   = args[2]
    format = args[3]

    task = Task.create!(name:          self.class.name,
                        indeterminate: true,
                        institution:   bs.institution,
                        started_at:    Time.now,
                        status_text:   "Generating #{region}/#{size} #{format} "\
                                       "derivative image for #{bs.original_filename}")
    begin
      bs.send(:generate_derivative, region: region, size: size, format: format)
    rescue => e
      task.fail(detail:    e.message,
                backtrace: e.backtrace)
    else
      task.succeed
    end
  end

end
