require 'test_helper'

class VocabularyTest < ActiveSupport::TestCase

  setup do
    @instance = Vocabulary.with_key(:common_types)
  end

  # all()

  test "all() returns all available vocabularies" do
    vocabs = Vocabulary.all
    assert_equal Vocabulary::Key.constants.length, vocabs.length
  end

  # with_key()

  test "with_key() accepts a string key" do
    assert_not_nil Vocabulary.with_key("common_types")
  end

  test "with_key() accepts a symbol key" do
    assert_not_nil Vocabulary.with_key(:common_types)
  end

  test "with_key() accepts all defined vocabulary keys" do
    assert_not_nil Vocabulary.with_key(:common_genres)
    assert_not_nil Vocabulary.with_key(:common_iso_languages)
    assert_not_nil Vocabulary.with_key(:common_types)
    assert_not_nil Vocabulary.with_key(:degree_names)
    assert_not_nil Vocabulary.with_key(:dissertation_thesis)
  end

  test "with_key() raises an error when given an unrecognized key" do
    assert_raises ArgumentError do
      Vocabulary.with_key(:bogus)
    end
  end

  # key

  test "key property is set" do
    assert_equal "common_types", @instance.key
  end

  # name()

  test "name() returns the vocabulary name" do
    assert_equal "Common Types", @instance.name
  end

  # terms()

  test "terms() returns all terms in a vocabulary" do
    assert_equal 6, @instance.terms.length
    assert_equal "sound", @instance.terms[0].stored_value
    assert_equal "Audio", @instance.terms[0].displayed_value
  end

end
