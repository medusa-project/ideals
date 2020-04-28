require 'test_helper'

class ApprovalStateTest < ActiveSupport::TestCase

  # all()

  test "all() returns all approval states" do
    assert_equal %w(approved rejected pending), ApprovalState.all
  end

end
