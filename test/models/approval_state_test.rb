require 'test_helper'

class ApprovalStateTest < ActiveSupport::TestCase

  # all()

  test "all() returns all approval states" do
    assert_equal Set.new(%w(approved rejected pending)),
                 Set.new(ApprovalState.all)
  end

end
