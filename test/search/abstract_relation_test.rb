require 'test_helper'

class AbstractRelationTest < ActiveSupport::TestCase

  setup do
    # We'll use this as our AbstractRelation implementation because it's
    # probably the simplest.
    @instance = UnitRelation.new
  end

  # facets

  test "facets() raises an error when aggregations are disabled" do
    @instance.aggregations(false)
    assert_raises do
      @instance.facets
    end
  end

end
