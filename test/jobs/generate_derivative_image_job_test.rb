require 'test_helper'

class GenerateDerivativeImageJobTest < ActiveSupport::TestCase

  setup do
    setup_s3
  end

  test "perform() updates the Task given to it" do
    bs   = bitstreams(:southeast_approved_in_permanent)
    task = tasks(:pending)

    GenerateDerivativeImageJob.perform_now(bitstream: bs,
                                           region:    :full,
                                           size:      512,
                                           format:    :jpg,
                                           task:      task)
    task.reload
    assert_equal "GenerateDerivativeImageJob", task.name
    assert_equal bs.institution, task.institution
    assert task.indeterminate
    assert_equal GenerateDerivativeImageJob::QUEUE.to_s, task.queue
    assert_not_empty task.job_id
    assert_not_empty task.status_text
  end

  test "perform() generates a derivative image" do
    bs = bitstreams(:southeast_approved_in_permanent)

    GenerateDerivativeImageJob.perform_now(bitstream: bs,
                                           region:    :full,
                                           size:      512,
                                           format:    :jpg,
                                           task:      tasks(:pending))

    key = DerivativeGenerator.new(bs).derivative_image_key(region: :full,
                                                           size:   512,
                                                           format: :jpg)
    assert ObjectStore.instance.object_exists?(key: key)
  end

end
