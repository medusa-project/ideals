require 'test_helper'

class ImportJobTest < ActiveSupport::TestCase

  setup do
    setup_s3
  end

  test "perform() associates a correct Task to the import" do
    import = imports(:uiuc_csv_file_new)
    import.update!(task: nil)
    import.upload_io(io:            File.new(file_fixture("csv/new.csv")),
                     relative_path: "new.csv")
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

  test "perform() runs the CSV file importer if the Import has one key ending
  in .csv" do
    import = imports(:uiuc_csv_file_new)
    import.upload_io(io:            File.new(file_fixture("csv/new.csv")),
                     relative_path: "new.csv")
    format = ImportJob.new.perform(import: import)
    assert_equal Import::Format::CSV_FILE, format
  end

  test "perform() runs the CSV package importer for CSV packages" do
    import = imports(:uiuc_csv_package_new)
    package_root = file_fixture_path + "/packages/csv/valid_items"
    Dir.glob(File.join(package_root, "**", "*")).each do |file|
      next if File.directory?(file)
      import.upload_io(io:            File.new(file),
                       relative_path: file.gsub(package_root, ""))
    end
    format = ImportJob.new.perform(import: import)
    assert_equal Import::Format::CSV_PACKAGE, format
  end

  test "perform() runs the SAF package importer for SAF packages" do
    import       = imports(:uiuc_saf_new)
    package_root = file_fixture_path + "/packages/saf/valid_item"
    Dir.glob(File.join(package_root, "**", "*")).each do |file|
      next if File.directory?(file)
      import.upload_io(io:            File.new(file),
                       relative_path: file.gsub(package_root, ""))
    end
    format = ImportJob.new.perform(import: import)
    assert_equal Import::Format::SAF, format
  end

end
