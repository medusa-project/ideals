require 'test_helper'

class ImportJobTest < ActiveSupport::TestCase

  test "perform() associates a correct Task to the import" do
    fixture = file_fixture("csv/new.csv")
    import  = imports(:southeast_csv_file_new)
    import.update!(task:     nil,
                   filename: File.basename(fixture),
                   length:   File.size(fixture))
    ObjectStore.instance.put_object(key:  import.file_key,
                                    path: fixture)

    user = users(:southwest)
    ImportJob.new.perform(import: import, user: user)
    import.reload

    task = import.task
    assert_equal "Importer", task.name
    assert_equal user.institution, task.institution
    assert_equal user, task.user
    assert !task.indeterminate
    assert_not_nil task.started_at
    assert task.status_text.start_with?("Import")
  end

  test "perform() deletes the import file" do
    fixture = file_fixture("csv/new.csv")
    import  = imports(:southeast_csv_file_new)
    import.update!(task:     nil,
                   filename: File.basename(fixture),
                   length:   File.size(fixture))
    ObjectStore.instance.put_object(key:  import.file_key,
                                    path: fixture)

    submitter = users(:southeast)
    ImportJob.new.perform(import: import, user: submitter)

    assert !File.exist?(import.file)
  end

  test "perform() runs the CSV file importer if the Import has one key ending
  in .csv" do
    fixture = file_fixture("csv/new.csv")
    import  = imports(:southeast_csv_file_new)
    import.update!(filename: File.basename(fixture),
                   length:   File.size(fixture))
    ObjectStore.instance.put_object(key:  import.file_key,
                                    path: fixture)

    format = ImportJob.new.perform(import: import)
    assert_equal Import::Format::CSV_FILE, format
  end

  test "perform() runs the CSV package importer for CSV packages" do
    import       = imports(:southeast_csv_package_new)
    package_root = File.join(file_fixture_path, "/packages/csv")
    csv_package  = File.join(Dir.tmpdir, "test.zip")
    `cd "#{package_root}" && rm -f #{csv_package} && zip -r "#{csv_package}" valid_items`
    import.update!(filename: File.basename(csv_package),
                   length:   File.size(csv_package))
    ObjectStore.instance.put_object(key:  import.file_key,
                                    path: csv_package)

    format = ImportJob.new.perform(import: import)
    assert_equal Import::Format::CSV_PACKAGE, format
  end

  test "perform() runs the SAF package importer for SAF packages" do
    import       = imports(:southeast_saf_new)
    package_root = File.join(file_fixture_path, "/packages/saf")
    saf_package  = File.join(Dir.tmpdir, "test.zip")
    `cd "#{package_root}" && rm -f #{saf_package} && zip -r "#{saf_package}" valid_item`
    import.update!(filename: File.basename(saf_package),
                   length:   File.size(saf_package))
    ObjectStore.instance.put_object(key:  import.file_key,
                                    path: saf_package)

    format = ImportJob.new.perform(import: import)
    assert_equal Import::Format::SAF, format
  end

end
