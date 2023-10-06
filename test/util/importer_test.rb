require 'test_helper'

class ImporterTest < ActiveSupport::TestCase

  setup do
    setup_s3
  end

  teardown do
    teardown_s3
  end

  test "import() associates a correct Task to the import" do
    fixture = file_fixture("csv/new.csv")
    import  = imports(:uiuc_csv_file_new)
    import.update!(task:     nil,
                   filename: File.basename(fixture),
                   length:   File.size(fixture))
    ObjectStore.instance.put_object(key:  import.file_key,
                                    path: fixture)
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

  test "import() supports an import file on the filesystem" do
    import       = imports(:uiuc_csv_package_new)
    package_root = File.join(file_fixture_path, "packages/csv")
    zip_package  = File.join(Dir.mktmpdir, "test.zip")
    `cd "#{package_root}" && rm -f #{zip_package} && zip -r "#{zip_package}" valid_items`
    import.update!(filename: File.basename(zip_package),
                   length:   File.size(zip_package))
    FileUtils.mkdir_p(File.dirname(import.file))
    FileUtils.cp(zip_package, import.file)

    format = Importer.new.import(import, users(:uiuc))
    assert_equal Import::Format::CSV_PACKAGE, format
  end

  test "import() supports an import file in the application S3 bucket" do
    import       = imports(:uiuc_csv_package_new)
    package_root = File.join(file_fixture_path, "packages/csv")
    zip_package  = File.join(Dir.mktmpdir, "test.zip")
    `cd "#{package_root}" && rm -f #{zip_package} && zip -r "#{zip_package}" valid_items`
    import.update!(filename: File.basename(zip_package),
                   length:   File.size(zip_package))
    ObjectStore.instance.put_object(key:  import.file_key,
                                    path: zip_package)

    format = Importer.new.import(import, users(:uiuc))
    assert_equal Import::Format::CSV_PACKAGE, format
  end

  test "import() runs the CSV file importer if the Import has a file ending
  in .csv" do
    import   = imports(:uiuc_csv_file_new)
    csv_file = file_fixture("csv/new.csv")
    import.update!(filename: File.basename(csv_file),
                   length:   File.size(csv_file))
    ObjectStore.instance.put_object(key:  import.file_key,
                                    path: csv_file)

    format = Importer.new.import(import, users(:uiuc))
    assert_equal Import::Format::CSV_FILE, format
  end

  test "import() runs the CSV package importer for CSV packages" do
    import       = imports(:uiuc_csv_package_new)
    package_root = File.join(file_fixture_path, "packages/csv")
    zip_package  = File.join(Dir.mktmpdir, "test.zip")
    `cd "#{package_root}" && rm -f #{zip_package} && zip -r "#{zip_package}" valid_items`
    import.update!(filename: File.basename(zip_package),
                   length:   File.size(zip_package))
    ObjectStore.instance.put_object(key:  import.file_key,
                                    path: zip_package)

    format = Importer.new.import(import, users(:uiuc))
    assert_equal Import::Format::CSV_PACKAGE, format
  end

  test "import() supports CSV packages without an enclosing directory" do
    import       = imports(:uiuc_csv_package_new)
    package_root = File.join(file_fixture_path, "packages/csv/valid_items")
    zip_package  = File.join(Dir.mktmpdir, "test.zip")
    `cd "#{package_root}" && rm -f #{zip_package} && zip -r "#{zip_package}" .`
    import.update!(filename: File.basename(zip_package),
                   length:   File.size(zip_package))
    ObjectStore.instance.put_object(key:  import.file_key,
                                    path: zip_package)

    format = Importer.new.import(import, users(:uiuc))
    assert_equal Import::Format::CSV_PACKAGE, format
  end

  test "import() supports CSV packages with an enclosing directory" do
    import       = imports(:uiuc_csv_package_new)
    package_root = File.join(file_fixture_path, "packages/csv")
    zip_package  = File.join(Dir.mktmpdir, "test.zip")
    `cd "#{package_root}" && rm -f #{zip_package} && zip -r "#{zip_package}" valid_items`
    import.update!(filename: File.basename(zip_package),
                   length:   File.size(zip_package))
    ObjectStore.instance.put_object(key:  import.file_key,
                                    path: zip_package)

    format = Importer.new.import(import, users(:uiuc))
    assert_equal Import::Format::CSV_PACKAGE, format
  end

  test "import() runs the SAF package importer for SAF packages" do
    import       = imports(:uiuc_saf_new)
    package_root = File.join(file_fixture_path, "packages/saf")
    zip_package  = File.join(Dir.tmpdir, "test.zip")
    `cd "#{package_root}" && rm -f #{zip_package} && zip -r "#{zip_package}" valid_item`
    import.update!(filename: File.basename(zip_package),
                   length:   File.size(zip_package))
    ObjectStore.instance.put_object(key:  import.file_key,
                                    path: zip_package)

    format = Importer.new.import(import, users(:uiuc))
    assert_equal Import::Format::SAF, format
  end

  test "import() supports SAF packages without an enclosing directory" do
    import       = imports(:uiuc_saf_new)
    package_root = File.join(file_fixture_path, "packages/saf/valid_item")
    zip_package  = File.join(Dir.tmpdir, "test.zip")
    `cd "#{package_root}" && rm -f #{zip_package} && zip -r "#{zip_package}" .`
    import.update!(filename: File.basename(zip_package),
                   length:   File.size(zip_package))
    ObjectStore.instance.put_object(key:  import.file_key,
                                    path: zip_package)

    format = Importer.new.import(import, users(:uiuc))
    assert_equal Import::Format::SAF, format
  end

  test "import() supports SAF packages with an enclosing directory" do
    import       = imports(:uiuc_saf_new)
    package_root = File.join(file_fixture_path, "packages/saf")
    zip_package  = File.join(Dir.tmpdir, "test.zip")
    `cd "#{package_root}" && rm -f #{zip_package} && zip -r "#{zip_package}" valid_item`
    import.update!(filename: File.basename(zip_package),
                   length:   File.size(zip_package))
    ObjectStore.instance.put_object(key:  import.file_key,
                                    path: zip_package)

    format = Importer.new.import(import, users(:uiuc))
    assert_equal Import::Format::SAF, format
  end

end
