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
    @instance = imports(:uiuc_saf_new)
    @instance.delete_all_files
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

  test "delete_all_files() deletes all corresponding files" do
    File.open(file_fixture("escher_lego.png"), "r") do |file|
      @instance.save_file(file:     file,
                          filename: File.basename(file.path))
    end
    assert File.exist?(@instance.file)

    @instance.delete_all_files
    assert !File.exist?(@instance.file)
  end

  # destroy()

  test "destroy() deletes all corresponding uploads " do
    fixture = file_fixture("escher_lego.png")
    File.open(fixture, "r") do |file|
      @instance.save_file(file:     file,
                          filename: File.basename(file.path))
    end

    assert File.exist?(@instance.file)

    @instance.destroy
    assert !File.exist?(@instance.file)
  end

  # file()

  test "file() returns nil if filename is blank" do
    assert_nil @instance.file
  end

  test "file() returns a correct pathname" do
    fixture = file_fixture("escher_lego.png")
    File.open(fixture, "r") do |file|
      @instance.save_file(file:     file,
                          filename: File.basename(file.path))
    end

    assert_equal File.join(@instance.filesystem_root, fixture.basename),
                 @instance.file
  end

  # filesystem_root()

  test "filesystem_root() raises an error for an instance that has not been
  persisted yet" do
    import = Import.new
    assert_raises do
      import.filesystem_root
    end
  end

  test "filesystem_root() returns the instance's filesystem root" do
    assert_equal File.join(Dir.tmpdir, "ideals_imports", @instance.institution.key, @instance.id.to_s),
                 @instance.filesystem_root
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

  # root_key_prefix()

  test "root_key_prefix() returns a correct value" do
    assert_equal "institutions/#{@instance.institution.key}/imports/#{@instance.id}/",
                 @instance.root_key_prefix
  end

  # save()

  test "save() deletes all uploaded files when the task is succeeded" do
    File.open(file_fixture("escher_lego.png"), "r") do |file|
      @instance.save_file(file:     file,
                          filename: File.basename(file.path))
    end
    assert File.exist?(@instance.file)
    @instance.task.succeed
    @instance.save!
    assert !File.exist?(@instance.file)
  end

  # save_file()

  test "save_file() updates the filename" do
    @instance.save_file(file:     File.new(file_fixture("pooh.jpg")),
                        filename: "pooh.jpg")
    assert_equal "pooh.jpg", @instance.filename
  end

  test "save_file() saves a file to a temporary location" do
    @instance.save_file(file:     File.new(file_fixture("pooh.jpg")),
                        filename: "pooh.jpg")
    assert File.exist?(File.join(@instance.filesystem_root, "pooh.jpg"))
  end

end
