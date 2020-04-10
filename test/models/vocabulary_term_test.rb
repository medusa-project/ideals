require 'test_helper'

class VocabularyTermTest < ActiveSupport::TestCase

  setup do
    @instance = VocabularyTerm.new("cats", "dogs")
  end

  test "initialize() initializes an instance" do
    assert_equal "cats", @instance.stored_value
    assert_equal "dogs", @instance.displayed_value
  end

end
