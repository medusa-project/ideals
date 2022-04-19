require 'test_helper'

class ReindexItemsJobTest < ActiveSupport::TestCase

  test "perform() reindexes items in the given collections" do
    # This is kind of hard to test, so for now we'll just check that it doesn't
    # error out.
    collections = [
      collections(:collection1),
      collections(:collection2)
    ]
    ReindexItemsJob.new.perform(collections)
  end

end
