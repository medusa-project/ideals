require 'test_helper'

class RoleTest < ActiveSupport::TestCase

  test "all() returns all constant values" do
    assert_equal Role.constants.map{ |c| Role.const_get(c) }.sort,
                 Role.all.sort
  end

end