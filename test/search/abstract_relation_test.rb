require 'test_helper'

class AbstractRelationTest < ActiveSupport::TestCase

  setup do
    # We'll use this as our AbstractRelation implementation because it's
    # probably the simplest.
    @instance = UserRelation.new
  end

  # facets

  test "facets() raises an error when aggregations are disabled" do
    @instance.aggregations(false)
    assert_raises do
      @instance.facets
    end
  end

  # remove_filter()

  test "remove_filter() removes all matching filters" do
    @instance.
        filter("bla", "cats").
        filter("bla", "dogs").
        filter("bla2", "foxes")
    @instance.remove_filter("bla")
    assert_equal [["bla2", "foxes"]],
                 @instance.instance_variable_get("@filters")
  end

end
