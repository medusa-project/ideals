require 'test_helper'

class VocabularyTermTest < ActiveSupport::TestCase

  setup do
    @term = vocabulary_terms(:southwest_one_one)
  end

  # displayed_value

  test "displayed_value is required" do
    @term.displayed_value = nil
    assert !@term.valid?
  end

  # stored_value

  test "stored_value is required" do
    @term.stored_value = nil
    assert !@term.valid?
  end

  # vocabulary

  test "vocabulary is required" do
    @term.vocabulary = nil
    assert !@term.valid?
  end

end
