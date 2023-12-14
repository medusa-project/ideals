require "test_helper"

class ImportTest < ActiveSupport::TestCase

  class FormatTest < ActiveSupport::TestCase

    test "to_s() returns a correct value" do
      assert_equal "SAF Package", Import::Format.to_s(Import::Format::SAF)
      assert_equal "CSV File", Import::Format.to_s(Import::Format::CSV_FILE)
      assert_equal "CSV Package", Import::Format.to_s(Import::Format::CSV_PACKAGE)
      assert_equal "Unknown", Import::Format.to_s(9999)
    end

  end

  setup do
    setup_s3
    @instance = imports(:southeast_saf_new)
  end

  teardown do
    @instance.delete_file
    teardown_s3
  end

  # collection

  test "collection is required" do
    assert @instance.valid?
    @instance.collection = nil
    assert !@instance.valid?
  end

  # delete_file()

  test "delete_file() deletes the corresponding file" do
    fixture = file_fixture("zip.zip")
    @instance.update!(filename: "zip.zip",
                      length:   File.size(fixture))
    FileUtils.mkdir_p(File.dirname(@instance.file))
    FileUtils.cp(file_fixture("zip.zip"), @instance.file)

    @instance.delete_file
    assert !File.exist?(@instance.file)
  end

  # delete_object()

  test "delete_object() deletes the corresponding bucket object" do
    fixture = file_fixture("zip.zip")
    @instance.update!(filename: "zip.zip",
                      length:   File.size(fixture))
    ObjectStore.instance.put_object(key:  @instance.file_key,
                                        path: fixture)

    @instance.delete_object
    assert !ObjectStore.instance.object_exists?(key: @instance.file_key)
  end

  # destroy()

  test "destroy() deletes the associated file" do
    fixture = file_fixture("zip.zip")
    @instance.update!(filename: "zip.zip",
                      length:   File.size(fixture))
    FileUtils.mkdir_p(File.dirname(@instance.file))
    FileUtils.cp(file_fixture("zip.zip"), @instance.file)

    @instance.destroy
    assert !File.exist?(@instance.file)
  end

  test "destroy() deletes the associated bucket object" do
    fixture = file_fixture("zip.zip")
    store   = ObjectStore.instance
    @instance.update!(filename: "zip.zip",
                      length:   File.size(fixture))
    store.put_object(key:  @instance.file_key,
                     path: fixture)

    @instance.destroy
    assert !store.object_exists?(key: @instance.file_key)
  end

  # download()

  test "download() raises an error if a file already exists at the
  destination" do
    fixture = file_fixture("zip.zip")
    @instance.update!(filename: "zip.zip",
                      length:   File.size(fixture))

    File.open(@instance.file, "wb") do |file|
      file << "hi"
    end
    assert_raises do
      @instance.download
    end
  end

  test "download() downloads a file from the application S3 bucket to the
  filesystem" do
    fixture = file_fixture("zip.zip")
    store   = ObjectStore.instance
    @instance.update!(filename: "zip.zip",
                      length:   File.size(fixture))
    store.put_object(key:  @instance.file_key,
                     path: fixture)

    @instance.download
    assert File.exist?(@instance.file)
  end

  # file()

  test "file() raises an error if the ID is not set" do
    assert_raises do
      Import.new.file
    end
  end

  test "file() raises an error if institution_id is not set" do
    @instance.institution_id = nil
    assert_raises do
      @instance.file
    end
  end

  test "file() raises an error if the filename is blank" do
    @instance.filename = nil
    assert_raises do
      @instance.file
    end
  end

  test "file() returns a correct pathname" do
    fixture = file_fixture("zip.zip")
    @instance.update!(filename: "zip.zip")

    assert_equal File.join(Dir.tmpdir, "ideals_imports",
                           @instance.institution.key, @instance.id.to_s,
                           fixture.basename),
                 @instance.file
  end

  # file_key()

  test "file_key() raises an error if the ID is not set" do
    assert_raises do
      Import.new.file_key
    end
  end

  test "file_key() raises an error if institution_id is not set" do
    @instance.institution_id = nil
    assert_raises do
      @instance.file_key
    end
  end

  test "file_key() raises an error if the filename is blank" do
    @instance.filename = nil
    assert_raises do
      @instance.file_key
    end
  end

  test "file_key() returns a correct key" do
    fixture = file_fixture("zip.zip")
    @instance.update!(filename: fixture.basename)

    assert_equal [Bitstream::INSTITUTION_KEY_PREFIX,
                      @instance.institution.key,
                      "imports",
                      @instance.id,
                      fixture.basename].join("/"),
                 @instance.file_key
  end

  # presigned_download_url()

  test "presigned_download_url() raises an error if filename is not set" do
    @instance.filename = nil
    assert_raises do
      @instance.presigned_download_url
    end
  end

  test "presigned_download_url() returns a URL" do
    @instance.filename = "zip.zip"
    assert_not_nil @instance.presigned_download_url
  end

  # presigned_upload_url()

  test "presigned_upload_url() raises an error if filename is not set" do
    @instance.filename = nil
    assert_raises do
      @instance.presigned_upload_url
    end
  end

  test "presigned_upload_url() returns a URL" do
    @instance.filename = "zip.zip"
    assert_not_nil @instance.presigned_upload_url
  end

  # progress()

  test "progress() updates imported_items" do
    percent_complete = 0.35
    imported_items   = [{ 'item_id' => 9999, 'handle' => "handle" }]
    @instance.progress(percent_complete, imported_items)
    assert_equal imported_items, @instance.imported_items
  end

  test "progress() updates the associated Task's percent_complete" do
    percent_complete = 0.35
    imported_items   = [{ 'item_id' => 9999, 'handle' => "handle" }]
    @instance.progress(percent_complete, imported_items)
    assert_equal percent_complete, @instance.task.percent_complete
  end

  # save()

  test "save() deletes the file when the task is succeeded" do
    # Copy the file in place
    fixture = file_fixture("zip.zip")
    @instance.update!(filename: "zip.zip",
                      length:   File.size(fixture))
    FileUtils.mkdir_p(File.dirname(@instance.file))
    FileUtils.cp(file_fixture("zip.zip"), @instance.file)

    @instance.task.succeed
    @instance.save!
    assert !File.exist?(@instance.file)
  end

end
