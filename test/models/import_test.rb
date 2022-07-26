require "test_helper"

class ImportTest < ActiveSupport::TestCase

  class KindTest < ActiveSupport::TestCase

    test "to_s() returns a correct value" do
      assert_equal "SAF Package", Import::Kind.to_s(Import::Kind::SAF)
      assert_equal "CSV File", Import::Kind.to_s(Import::Kind::CSV)
      assert_equal "Unknown", Import::Kind.to_s(9999)
    end

  end

  setup do
    setup_s3
    @instance = imports(:saf_new)
  end

  teardown do
    teardown_s3
  end

  # collection

  test "collection is required" do
    assert @instance.valid?
    @instance.collection = nil
    assert !@instance.valid?
  end

  # delete_all_files()

  test "delete_all_files() deletes all corresponding files from the application
  S3 bucket" do
    File.open(file_fixture("escher_lego.jpg"), "r") do |file|
      @instance.upload_file(relative_path: "item1/escher_lego.jpg",
                            io:            file)
    end
    assert_equal 1, @instance.object_keys.length

    @instance.delete_all_files
    assert_equal 0, @instance.object_keys.length
  end

  # destroy()

  test "destroy() deletes all corresponding uploads from the application S3
  bucket" do
    fixture = file_fixture("escher_lego.jpg")
    File.open(fixture, "r") do |file|
      @instance.upload_file(relative_path: "item1/escher_lego1.jpg",
                            io:            file)
    end
    assert_equal 1, @instance.object_keys.length

    @instance.destroy
    assert_empty @instance.object_keys
  end

  # item_key_prefixes()

  test "item_key_prefixes() returns all item key prefixes" do
    fixture = file_fixture("escher_lego.jpg")
    File.open(fixture, "r") do |file|
      @instance.upload_file(relative_path: "item1/escher_lego1.jpg",
                            io:            file)
    end
    File.open(fixture, "r") do |file|
      @instance.upload_file(relative_path: "item1/escher_lego2.jpg",
                            io:            file)
    end
    File.open(fixture, "r") do |file|
      @instance.upload_file(relative_path: "item2/escher_lego1.jpg",
                            io:            file)
    end
    prefixes = @instance.item_key_prefixes
    assert_equal 2, prefixes.count
    assert_equal "imports/#{@instance.id}/item1", prefixes[0]
    assert_equal "imports/#{@instance.id}/item2", prefixes[1]
  end

  # object_key()

  test "object_key() returns a correct value" do
    assert_equal "imports/#{@instance.id}/item1/cats.jpg",
                 @instance.object_key("/item1/cats.jpg")
  end

  # object_keys()

  test "object_keys() returns all object keys" do
    fixture = file_fixture("escher_lego.jpg")
    File.open(fixture, "r") do |file|
      @instance.upload_file(relative_path: "item1/escher_lego1.jpg",
                            io:            file)
    end
    File.open(fixture, "r") do |file|
      @instance.upload_file(relative_path: "item1/escher_lego2.jpg",
                            io:            file)
    end
    keys = @instance.object_keys
    assert_equal 2, keys.count
    assert_equal @instance.object_key("item1/escher_lego1.jpg"), keys[0]
    assert_equal @instance.object_key("item1/escher_lego2.jpg"), keys[1]
  end

  # progress()

  test "progress() updates percent_complete and imported_items" do
    percent_complete = 0.35
    imported_items   = [{ 'item_id' => 9999, 'handle' => "handle" }]
    @instance.progress(percent_complete, imported_items)
    assert_equal percent_complete, @instance.percent_complete
    assert_equal imported_items, @instance.imported_items
  end

  # status

  test "status must be set to one of the Status constants" do
    @instance.status = Import::Status::NEW
    assert @instance.valid?
    @instance.status = 95
    assert !@instance.valid?
  end

  # root_key_prefix()

  test "root_key_prefix() returns a correct value" do
    assert_equal "imports/#{@instance.id}/", @instance.root_key_prefix
  end

  # save()

  test "save() sets percent_complete to 1 when the status is set to success" do
    assert_equal 0, @instance.percent_complete
    @instance.update!(status: Import::Status::SUCCEEDED)
    assert_equal 1, @instance.percent_complete
  end

  test "save() deletes all uploaded files when the status is set to succeeded" do
    File.open(file_fixture("escher_lego.jpg"), "r") do |file|
      @instance.upload_file(relative_path: "item1/escher_lego.jpg",
                            io:            file)
    end
    assert_equal 1, @instance.object_keys.length
    @instance.update!(status: Import::Status::SUCCEEDED)
    assert_equal 0, @instance.object_keys.length
  end

  # upload_file()

  test "upload_file() uploads a file" do
    File.open(file_fixture("escher_lego.jpg"), "r") do |file|
      @instance.upload_file(relative_path: "item1/escher_lego.jpg",
                            io:            file)
    end
    expected_key = @instance.object_key("item1/escher_lego.jpg")
    assert S3Client.instance.object_exists?(bucket: ::Configuration.instance.storage[:bucket],
                                            key:    expected_key)
  end

end
