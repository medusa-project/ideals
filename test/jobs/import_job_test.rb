require 'test_helper'

class ImportJobTest < ActiveSupport::TestCase

  setup do
    setup_s3
  end

  test "perform() associates a correct Task to the import" do
    import = imports(:uiuc_csv_new)
    import.update!(task: nil)
    import.upload_file(relative_path: "new.csv",
                       io:            file_fixture("csv/new.csv"))
    user = users(:southwest)
    ImportJob.new.perform(import: import, user: user)
    import.reload

    task = import.task
    assert_equal "ImportJob", task.name
    assert_equal user.institution, task.institution
    assert_equal user, task.user
    assert !task.indeterminate
    assert_not_nil task.started_at
    assert task.status_text.start_with?("Import")
  end

  test "perform() runs the CSV importer if the Import has one key ending in
  .csv" do
    import = imports(:uiuc_csv_new)
    import.upload_file(relative_path: "new.csv",
                       io:            file_fixture("csv/new.csv"))
    format = ImportJob.new.perform(import: import)
    assert_equal Import::Format::CSV, format
  end

  test "perform() runs the SAF importer if the Import has multiple keys" do
    import = imports(:uiuc_saf_new)
    format = ImportJob.new.perform(import: import)
    assert_equal Import::Format::SAF, format
  end

end
