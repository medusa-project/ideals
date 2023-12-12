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

  test "perform() updates the Task given to it" do
    vocabulary = vocabularies(:southwest_one)
    user       = users(:southwest)
    task       = tasks(:pending)
    ImportVocabularyTermsJob.perform_now(vocabulary: vocabulary,
                                         pathname:   @csv_path,
                                         user:       user,
                                         task:       task)

    task.reload
    assert_equal "ImportVocabularyTermsJob", task.name
    assert_equal vocabulary.institution, task.institution
    assert_equal user, task.user
    assert !task.indeterminate
    assert_not_nil task.started_at
    assert_not_empty task.job_id
    assert_equal ImportVocabularyTermsJob::QUEUE.to_s, task.queue
    assert_equal "Importing vocabulary terms into #{vocabulary.name}",
                 task.status_text
  end

  test "perform() imports terms" do
    vocabulary    = vocabularies(:southwest_one)
    user          = users(:southwest)
    initial_count = VocabularyTerm.count
    ImportVocabularyTermsJob.perform_now(vocabulary: vocabulary,
                                         pathname:   @csv_path,
                                         user:       user)

    # This is tested more thoroughly in the test of
    # Vocabulary.import_terms_from_csv().
    assert_equal initial_count + 3, VocabularyTerm.count
  end

end
