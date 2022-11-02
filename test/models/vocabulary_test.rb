require 'test_helper'

class VocabularyTest < ActiveSupport::TestCase

  setup do
    @instance = Vocabulary.find_by(institution: institutions(:southwest),
                                   key:         "vocab1")
  end

  # vocabulary

  test "institution is required" do
    @instance.institution = nil
    assert !@instance.valid?
  end

  # key

  test "key must not be nil" do
    @instance.key = nil
    assert !@instance.valid?
  end

  # name

  test "name must not be nil" do
    @instance.name = nil
    assert !@instance.valid?
  end

end
