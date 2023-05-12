require 'test_helper'

class ReadFullTextJobTest < ActiveSupport::TestCase

  setup do
    setup_s3
  end

  test "perform() creates a correct Task" do
    bs   = bitstreams(:uiuc_approved_in_permanent)
    user = users(:uiuc)

    ReadFullTextJob.new.perform(bitstream: bs, user: user)

    task = Task.all.order(created_at: :desc).limit(1).first
    assert_equal "ReadFullTextJob", task.name
    assert_equal user.institution, task.institution
    assert_equal user, task.user
    assert task.indeterminate
    assert task.status_text.start_with?("Reading full text")
  end

  test "perform() reads full text" do
    bs = bitstreams(:uiuc_approved_in_permanent)
    bs.update!(full_text_checked_at: nil,
               full_text:            nil)

    ReadFullTextJob.new.perform(bitstream: bs)
    assert_not_nil bs.full_text_checked_at
    assert_not_nil bs.full_text.text
  end

end
