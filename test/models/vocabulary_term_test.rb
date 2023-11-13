require 'test_helper'

class VocabularyTermTest < ActiveSupport::TestCase

  setup do
    @instance = vocabulary_terms(:southwest_one_one)
  end

  # displayed_value

  test "displayed_value is required" do
    @instance.displayed_value = nil
    assert !@instance.valid?
  end

  test "displayed_value is normalized" do
    @instance.displayed_value = " test  test "
    assert_equal "test test", @instance.displayed_value
  end

  # stored_value

  test "stored_value is required" do
    @instance.stored_value = nil
    assert !@instance.valid?
  end

  test "stored_value is normalized" do
    @instance.stored_value = " test  test "
    assert_equal "test test", @instance.stored_value
  end

  # vocabulary

  test "vocabulary is required" do
    @instance.vocabulary = nil
    assert !@instance.valid?
  end

end
