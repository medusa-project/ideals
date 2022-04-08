require 'test_helper'

class ReadFullTextJobTest < ActiveSupport::TestCase

  setup do
    setup_s3
  end

  test "perform() reads full text" do
    bs = bitstreams(:approved_in_permanent)
    bs.update!(full_text_checked_at: nil,
               full_text:            nil)

    ReadFullTextJob.new.perform(bs)
    assert_not_nil bs.full_text_checked_at
    assert_not_nil bs.full_text
  end

end
