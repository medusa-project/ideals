require 'test_helper'

class VocabularyTest < ActiveSupport::TestCase

  setup do
    @instance = Vocabulary.find_by(institution: institutions(:southwest),
                                   name:        "Vocabulary 1")
  end

  # vocabulary

  test "institution is required" do
    @instance.institution = nil
    assert !@instance.valid?
  end

  # import_terms_from_csv()

  test "import_terms_from_csv() raises an error for malformed CSV" do
    csv = "stored value\ncats" # missing displayed value
    assert_raises do
      @instance.import_terms_from_csv(csv: csv)
    end
  end

  test "import_terms_from_csv() imports terms from a file" do
    csv           = file_fixture("vocabulary_terms.csv")
    initial_count = @instance.vocabulary_terms.count
    @instance.import_terms_from_csv(pathname: csv)

    @instance.reload
    assert_equal initial_count + 3, @instance.vocabulary_terms.count
    term = VocabularyTerm.order(created_at: :desc).limit(1).first
    assert_equal @instance, term.vocabulary
    assert_equal "Bald Eagle", term.displayed_value
    assert_equal "bald eagle", term.stored_value
  end

  test "import_terms_from_csv() imports terms from a CSV string" do
    csv = "displayed value,stored value\n"\
          "Cats,cats\n"\
          "Dogs,dogs\n"\
          "Bald Eagle,bald eagle\n"
    initial_count = @instance.vocabulary_terms.count
    @instance.import_terms_from_csv(csv: csv)

    @instance.reload
    assert_equal initial_count + 3, @instance.vocabulary_terms.count
    term = VocabularyTerm.order(created_at: :desc).limit(1).first
    assert_equal @instance, term.vocabulary
    assert_equal "Bald Eagle", term.displayed_value
    assert_equal "bald eagle", term.stored_value
  end

  test "import_terms_from_csv() updates existing terms" do
    csv = file_fixture("vocabulary_terms.csv")
    @instance.vocabulary_terms.build(stored_value: "cat", displayed_value: "OldCat").save!
    @instance.import_terms_from_csv(pathname: csv)

    @instance.reload
    assert_equal "Cat", @instance.vocabulary_terms.where(stored_value: "cat").first.displayed_value
  end

  # name

  test "name must not be nil" do
    @instance.name = nil
    assert !@instance.valid?
  end

end
