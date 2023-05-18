require 'test_helper'

class ImportVocabularyTermsJobTest < ActiveSupport::TestCase

  setup do
    # Copy the source CSV file into a temp file before giving it to the job,
    # otherwise it will get deleted.
    tempfile  = Tempfile.new("temp")
    @csv_path = tempfile.path
    tempfile.unlink

    csv = file_fixture("vocabulary_terms.csv")
    FileUtils.cp(csv, @csv_path)
  end

  test "perform() creates a correct Task" do
    vocabulary = vocabularies(:southwest_one)
    user       = users(:southwest)
    ImportVocabularyTermsJob.new.perform(vocabulary: vocabulary,
                                         pathname:   @csv_path,
                                         user:       user)

    task = Task.all.order(created_at: :desc).limit(1).first
    assert_equal "ImportVocabularyTermsJob", task.name
    assert_equal vocabulary.institution, task.institution
    assert_equal user, task.user
    assert !task.indeterminate
    assert_not_nil task.started_at
    assert_equal "Importing vocabulary terms into #{vocabulary.name}",
                 task.status_text
  end

  test "perform() imports terms" do
    vocabulary    = vocabularies(:southwest_one)
    user          = users(:southwest)
    initial_count = VocabularyTerm.count
    ImportVocabularyTermsJob.new.perform(vocabulary: vocabulary,
                                         pathname:   @csv_path,
                                         user:       user)

    # This is tested more thoroughly in the test of
    # Vocabulary.import_terms_from_csv().
    assert_equal initial_count + 3, VocabularyTerm.count
  end

end
