require 'test_helper'

class ReadFullTextJobTest < ActiveSupport::TestCase

  setup do
    setup_s3
  end

  test "perform() updates the Task given to it" do
    bs   = bitstreams(:southeast_approved_in_permanent)
    user = users(:southeast)
    task = tasks(:pending)

    ReadFullTextJob.perform_now(bitstream: bs,
                                user:      user,
                                task:      task)

    task.reload
    assert_equal "ReadFullTextJob", task.name
    assert_equal user.institution, task.institution
    assert_equal user, task.user
    assert task.indeterminate
    assert_equal ReadFullTextJob::QUEUE.to_s, task.queue
    assert_not_empty task.job_id
    assert_not_nil task.started_at
    assert task.status_text.start_with?("Reading full text")
  end

  test "perform() reads full text" do
    bs = bitstreams(:southeast_approved_in_permanent)
    bs.update!(full_text_checked_at: nil,
               full_text:            nil)

    ReadFullTextJob.new.perform(bitstream: bs)
    assert_not_nil bs.full_text_checked_at
    assert_not_nil bs.full_text.text
  end

end
