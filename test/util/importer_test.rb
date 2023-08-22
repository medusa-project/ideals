require 'test_helper'

class ImporterTest < ActiveSupport::TestCase

  setup do
    setup_s3
  end

  test "perform() associates a correct Task to the import" do
    import = imports(:uiuc_csv_file_new)
    import.update!(task: nil)
    import.save_file(file:     File.new(file_fixture("csv/new.csv")),
                     filename: "new.csv")
    submitter = users(:uiuc)
    Importer.new.import(import, submitter)
    import.reload

    task = import.task
    assert_equal "Importer", task.name
    assert_equal submitter.institution, task.institution
    assert_equal submitter, task.user
    assert !task.indeterminate
    assert_not_nil task.started_at
    assert task.status_text.start_with?("Import")
  end

  test "perform() runs the CSV file importer if the Import has a file ending
  in .csv" do
    import = imports(:uiuc_csv_file_new)
    import.save_file(file:     File.new(file_fixture("csv/new.csv")),
                     filename: "new.csv")
    format = Importer.new.import(import, users(:uiuc))
    assert_equal Import::Format::CSV_FILE, format
  end

  test "perform() runs the CSV package importer for CSV packages" do
    import       = imports(:uiuc_csv_package_new)
    FileUtils.rm_rf(import.filesystem_root)
    package_root = File.join(file_fixture_path, "packages/csv")
    zip_package  = File.join(Dir.mktmpdir, "test.zip")
    `cd "#{package_root}" && rm -f #{zip_package} && zip -r "#{zip_package}" valid_items`
    import.save_file(file:     File.new(zip_package),
                     filename: File.basename(zip_package))

    format = Importer.new.import(import, users(:uiuc))
    assert_equal Import::Format::CSV_PACKAGE, format
  end

  test "perform() supports CSV packages without an enclosing directory" do
    import       = imports(:uiuc_csv_package_new)
    FileUtils.rm_rf(import.filesystem_root)
    package_root = File.join(file_fixture_path, "packages/csv/valid_items")
    zip_package  = File.join(Dir.mktmpdir, "test.zip")
    `cd "#{package_root}" && rm -f #{zip_package} && zip -r "#{zip_package}" .`
    import.save_file(file:     File.new(zip_package),
                     filename: File.basename(zip_package))

    format = Importer.new.import(import, users(:uiuc))
    assert_equal Import::Format::CSV_PACKAGE, format
  end

  test "perform() supports CSV packages with an enclosing directory" do
    import       = imports(:uiuc_csv_package_new)
    FileUtils.rm_rf(import.filesystem_root)
    package_root = File.join(file_fixture_path, "packages/csv")
    zip_package  = File.join(Dir.mktmpdir, "test.zip")
    `cd "#{package_root}" && rm -f #{zip_package} && zip -r "#{zip_package}" valid_items`
    import.save_file(file:     File.new(zip_package),
                     filename: File.basename(zip_package))

    format = Importer.new.import(import, users(:uiuc))
    assert_equal Import::Format::CSV_PACKAGE, format
  end

  test "perform() runs the SAF package importer for SAF packages" do
    import       = imports(:uiuc_saf_new)
    FileUtils.rm_rf(import.filesystem_root)
    package_root = File.join(file_fixture_path, "packages/saf")
    zip_package  = File.join(Dir.tmpdir, "test.zip")
    `cd "#{package_root}" && rm -f #{zip_package} && zip -r "#{zip_package}" valid_item`
    import.save_file(file:     File.new(zip_package),
                     filename: File.basename(zip_package))
    format = Importer.new.import(import, users(:uiuc))
    assert_equal Import::Format::SAF, format
  end

  test "perform() supports SAF packages without an enclosing directory" do
    import       = imports(:uiuc_saf_new)
    FileUtils.rm_rf(import.filesystem_root)
    package_root = File.join(file_fixture_path, "packages/saf/valid_item")
    zip_package  = File.join(Dir.tmpdir, "test.zip")
    `cd "#{package_root}" && rm -f #{zip_package} && zip -r "#{zip_package}" .`
    import.save_file(file:     File.new(zip_package),
                     filename: File.basename(zip_package))
    format = Importer.new.import(import, users(:uiuc))
    assert_equal Import::Format::SAF, format
  end

  test "perform() supports SAF packages with an enclosing directory" do
    import       = imports(:uiuc_saf_new)
    FileUtils.rm_rf(import.filesystem_root)
    package_root = File.join(file_fixture_path, "packages/saf")
    zip_package  = File.join(Dir.tmpdir, "test.zip")
    `cd "#{package_root}" && rm -f #{zip_package} && zip -r "#{zip_package}" valid_item`
    import.save_file(file:     File.new(zip_package),
                     filename: File.basename(zip_package))
    format = Importer.new.import(import, users(:uiuc))
    assert_equal Import::Format::SAF, format
  end

end
