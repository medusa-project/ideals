require 'test_helper'

class SafImporterTest < ActiveSupport::TestCase

  PACKAGES_PATH = File.join(Rails.root, "test", "fixtures", "saf_packages")

  setup do
    setup_s3
    setup_opensearch
    @instance = SafImporter.new
  end

  teardown do
    teardown_s3
  end

  # import_from_path()

  test "import_from_path() raises an error for a missing content file" do
    package = File.join(PACKAGES_PATH, "missing_content_file")
    assert_raises IOError do
      @instance.import_from_path(pathname:           package,
                                 primary_collection: collections(:uiuc_collection1),
                                 mapfile_path:       Tempfile.new("test"))
    end
  end

  test "import_from_path() raises an error for a missing file component on a
  line of the content file" do
    package = File.join(PACKAGES_PATH, "missing_file_on_content_file_line")
    assert_raises IOError do
      @instance.import_from_path(pathname:           package,
                                 primary_collection: collections(:uiuc_collection1),
                                 mapfile_path:       Tempfile.new("test"))
    end
  end

  test "import_from_path() raises an error for an illegal flag in a content
  file" do
    package = File.join(PACKAGES_PATH, "illegal_content_file_flag")
    assert_raises IOError do
      @instance.import_from_path(pathname:           package,
                                 primary_collection: collections(:uiuc_collection1),
                                 mapfile_path:       Tempfile.new("test"))
    end
  end

  test "import_from_path() raises an error for a missing file that is present
  in the content file" do
    package = File.join(PACKAGES_PATH, "missing_file")
    assert_raises IOError do
      @instance.import_from_path(pathname:           package,
                                 primary_collection: collections(:uiuc_collection1),
                                 mapfile_path:       Tempfile.new("test"))
    end
  end

  test "import_from_path() raises an error for a missing dublin_core.xml file" do
    package = File.join(PACKAGES_PATH, "missing_dublin_core")
    assert_raises IOError do
      @instance.import_from_path(pathname:           package,
                                 primary_collection: collections(:uiuc_collection1),
                                 mapfile_path:       Tempfile.new("test"))
    end
  end

  test "import_from_path() raises an error when encountering a registered
  element not present in the registry" do
    package = File.join(PACKAGES_PATH, "illegal_metadata_element")
    assert_raises IOError do
      @instance.import_from_path(pathname:           package,
                                 primary_collection: collections(:uiuc_collection1),
                                 mapfile_path:       Tempfile.new("test"))
    end
  end

  test "import_from_path() creates correct items" do
    package = File.join(PACKAGES_PATH, "valid_item")
    @instance.import_from_path(pathname:           package,
                               primary_collection: collections(:uiuc_collection1),
                               mapfile_path:       Tempfile.new("test"))

    # Test the created item's immediate properties
    item = Item.order(created_at: :desc).limit(1).first
    assert_not_nil item.handle
    assert_equal Item::Stages::APPROVED, item.stage

    # Test bitstream #1
    assert_equal 2, item.bitstreams.count
    bs = item.bitstreams.where(filename: "hello.txt").first
    assert_equal File.size(File.join(PACKAGES_PATH, "valid_item", "item_1", "hello.txt")),
                 bs.length
    assert_equal Bitstream::Bundle::CONTENT, bs.bundle
    assert_equal Bitstream.permanent_key(institution_key: bs.institution.key,
                                         item_id:         bs.item_id,
                                         filename:        bs.filename),
                 bs.permanent_key
    assert_equal "Hello world", bs.description
    assert bs.primary

    # Test bitstream #2
    bs = item.bitstreams.where(filename: "license.txt").first
    assert_equal File.size(File.join(PACKAGES_PATH, "valid_item", "item_1", "license.txt")),
                 bs.length
    assert_equal Bitstream::Bundle::LICENSE, bs.bundle
    assert_equal Bitstream.permanent_key(institution_key: bs.institution.key,
                                         item_id:         bs.item_id,
                                         filename:        bs.filename),
                 bs.permanent_key
    assert_equal "License file", bs.description
    assert !bs.primary

    # Test metadata
    assert_equal 9, item.elements.length
    assert_not_nil item.element(item.institution.date_approved_element.name)  # added automatically upon approval
    assert_not_nil item.element(item.institution.handle_uri_element.name) # added automatically when the handle is assigned
    assert_equal "Escher Lego", item.element("dc:title").string
    assert_equal "Subject 1", item.elements.select{ |e| e.name == "dc:subject"}[0].string
    assert_equal 1, item.elements.select{ |e| e.name == "dc:subject"}[0].position
    assert_equal "Subject 2", item.elements.select{ |e| e.name == "dc:subject"}[1].string
    assert_equal 2, item.elements.select{ |e| e.name == "dc:subject"}[1].position
    assert_equal "2021", item.element("dc:date:submitted").string
    assert_equal "Computer Science", item.element("thesis:degree:department").string
    assert_equal "Masters", item.element("thesis:degree:level").string
    assert_equal "Michigan Institute of Technology", item.element("thesis:degree:grantor").string
  end

  test "import_from_path() supports a content file named contents" do
    package = File.join(PACKAGES_PATH, "valid_item_2")
    @instance.import_from_path(pathname:           package,
                               primary_collection: collections(:uiuc_collection1),
                               mapfile_path:       Tempfile.new("test"))

    # Test the created item's immediate properties
    item = Item.order(created_at: :desc).limit(1).first
    assert_not_nil item.handle
    assert_equal Item::Stages::APPROVED, item.stage

    # Test bitstream #1
    assert_equal 2, item.bitstreams.count
    bs = item.bitstreams.where(filename: "README.txt").first
    assert_equal File.size(File.join(PACKAGES_PATH, "valid_item_2", "item_1", "README.txt")),
                 bs.length
    assert_equal Bitstream::Bundle::CONTENT, bs.bundle
    assert_equal Bitstream.permanent_key(institution_key: bs.institution.key,
                                         item_id:         bs.item_id,
                                         filename:        bs.filename),
                 bs.permanent_key
    assert_equal "Hello world", bs.description
    assert bs.primary

    # Test bitstream #2
    bs = item.bitstreams.where(filename: "license.txt").first
    assert_equal File.size(File.join(PACKAGES_PATH, "valid_item_2", "item_1", "license.txt")),
                 bs.length
    assert_equal Bitstream::Bundle::LICENSE, bs.bundle
    assert_equal Bitstream.permanent_key(institution_key: bs.institution.key,
                                         item_id:         bs.item_id,
                                         filename:        bs.filename),
                 bs.permanent_key
    assert_equal "License file", bs.description
    assert !bs.primary
  end

  test "import_from_path() supports uppercase content file keys" do
    package = File.join(PACKAGES_PATH, "valid_item_2")
    @instance.import_from_path(pathname:           package,
                               primary_collection: collections(:uiuc_collection1),
                               mapfile_path:       Tempfile.new("test"))

    # Test the created item's immediate properties
    item = Item.order(created_at: :desc).limit(1).first
    assert_not_nil item.handle
    assert_equal Item::Stages::APPROVED, item.stage

    # Test bitstream #1
    assert_equal 2, item.bitstreams.count
    bs = item.bitstreams.where(filename: "README.txt").first
    assert_equal File.size(File.join(PACKAGES_PATH, "valid_item_2", "item_1", "README.txt")),
                 bs.length
    assert_equal Bitstream::Bundle::CONTENT, bs.bundle
    assert_equal Bitstream.permanent_key(institution_key: bs.institution.key,
                                         item_id:         bs.item_id,
                                         filename:        bs.filename),
                 bs.permanent_key
    assert_equal "Hello world", bs.description
    assert bs.primary

    # Test bitstream #2
    bs = item.bitstreams.where(filename: "license.txt").first
    assert_equal File.size(File.join(PACKAGES_PATH, "valid_item_2", "item_1", "license.txt")),
                 bs.length
    assert_equal Bitstream::Bundle::LICENSE, bs.bundle
    assert_equal Bitstream.permanent_key(institution_key: bs.institution.key,
                                         item_id:         bs.item_id,
                                         filename:        bs.filename),
                 bs.permanent_key
    assert_equal "License file", bs.description
    assert !bs.primary
  end

  test "import_from_path() adds correct mapfile lines upon failure" do
    package = File.join(PACKAGES_PATH, "one_invalid_item")
    Tempfile.open("test") do |mapfile|
      assert_raises IOError do
        @instance.import_from_path(pathname:           package,
                                   primary_collection: collections(:uiuc_collection1),
                                   mapfile_path:       mapfile.path)
      end
      contents = mapfile.read
      assert_match /\Aitem_1\t\d+\/\d+\b/, contents
    end
  end

  test "import_from_path() trims whitespace from metadata element values" do
    package = File.join(PACKAGES_PATH, "valid_item_2")
    @instance.import_from_path(pathname:           package,
                               primary_collection: collections(:uiuc_collection1),
                               mapfile_path:       Tempfile.new("test"))

    item = Item.order(created_at: :desc).limit(1).first
    assert_equal "Whitespace Test", item.element("dc:title").string
    assert_equal "Subject", item.elements.select{ |e| e.name == "dc:subject"}[0].string
    assert_equal 1, item.elements.select{ |e| e.name == "dc:subject"}[0].position
    assert_equal "2021", item.element("dc:date:submitted").string
  end

  test "import_from_path() adds correct mapfile lines upon success" do
    package       = File.join(PACKAGES_PATH, "valid_item")
    Tempfile.open("test") do |mapfile|
      @instance.import_from_path(pathname:           package,
                                 primary_collection: collections(:uiuc_collection1),
                                 mapfile_path:       mapfile)
      # Get the created item
      item = Item.order(created_at: :desc).limit(1).first
      assert_equal "item_1\t#{item.handle.handle}\n", mapfile.read
    end
  end

  test "import_from_path() skips items present in the mapfile" do
    package = File.join(PACKAGES_PATH, "valid_item")
    assert_no_changes "Item.count" do
      mapfile = Tempfile.new("test")
      begin
        File.open(mapfile.path, "w") do |file|
          file.write("item_1\t100/100\n")
        end
        @instance.import_from_path(pathname:           package,
                                   primary_collection: collections(:uiuc_collection1),
                                   mapfile_path:       mapfile)
      ensure
        mapfile.close
        mapfile.unlink
      end
    end
  end

  # import_from_s3()

  test "import_from_s3() raises an error for a missing content file" do
    package = File.join(PACKAGES_PATH, "missing_content_file")
    import  = imports(:uiuc_saf_new)
    upload_to_s3(package, import)

    assert_raises IOError do
      @instance.import_from_s3(import)
    end
  end

  test "import_from_s3() raises an error for a missing file component on a line
  of the content file" do
    package = File.join(PACKAGES_PATH, "missing_file_on_content_file_line")
    import  = imports(:uiuc_saf_new)
    upload_to_s3(package, import)

    assert_raises IOError do
      @instance.import_from_s3(import)
    end
  end

  test "import_from_s3() raises an error for an illegal flag in a content file" do
    package = File.join(PACKAGES_PATH, "illegal_content_file_flag")
    import  = imports(:uiuc_saf_new)
    upload_to_s3(package, import)

    assert_raises IOError do
      @instance.import_from_s3(import)
    end
  end

  test "import_from_s3() raises an error for a missing file that is present in
  the content file" do
    package = File.join(PACKAGES_PATH, "missing_file")
    import  = imports(:uiuc_saf_new)
    upload_to_s3(package, import)

    assert_raises IOError do
      @instance.import_from_s3(import)
    end
  end

  test "import_from_s3() raises an error for a missing dublin_core.xml file" do
    package = File.join(PACKAGES_PATH, "missing_dublin_core")
    import  = imports(:uiuc_saf_new)
    upload_to_s3(package, import)

    assert_raises IOError do
      @instance.import_from_s3(import)
    end
  end

  test "import_from_s3() raises an error when encountering a registered element
  not present in the registry" do
    package = File.join(PACKAGES_PATH, "illegal_metadata_element")
    import  = imports(:uiuc_saf_new)
    upload_to_s3(package, import)

    assert_raises IOError do
      @instance.import_from_s3(import)
    end
  end

  test "import_from_s3() sets the import kind" do
    package = File.join(PACKAGES_PATH, "valid_item")
    import  = imports(:uiuc_saf_new)
    upload_to_s3(package, import)
    @instance.import_from_s3(import)

    assert_equal Import::Kind::SAF, import.kind
  end

  test "import_from_s3() creates correct items" do
    package = File.join(PACKAGES_PATH, "valid_item")
    import  = imports(:uiuc_saf_new)
    upload_to_s3(package, import)
    @instance.import_from_s3(import)

    # Test the created item's immediate properties
    item = Item.order(created_at: :desc).limit(1).first
    assert_not_nil item.handle
    assert_equal Item::Stages::APPROVED, item.stage

    # Test bitstream #1
    assert_equal 2, item.bitstreams.count
    bs = item.bitstreams.where(filename: "hello.txt").first
    assert_equal File.size(File.join(PACKAGES_PATH, "valid_item", "item_1", "hello.txt")),
                 bs.length
    assert_equal Bitstream::Bundle::CONTENT, bs.bundle
    assert_equal Bitstream.permanent_key(institution_key: bs.institution.key,
                                         item_id:         bs.item_id,
                                         filename:        bs.filename),
                 bs.permanent_key
    assert_equal "Hello world", bs.description
    assert bs.primary

    # Test bitstream #2
    bs = item.bitstreams.where(filename: "license.txt").first
    assert_equal File.size(File.join(PACKAGES_PATH, "valid_item", "item_1", "license.txt")),
                 bs.length
    assert_equal Bitstream::Bundle::LICENSE, bs.bundle
    assert_equal Bitstream.permanent_key(institution_key: bs.institution.key,
                                         item_id:         bs.item_id,
                                         filename:        bs.filename),
                 bs.permanent_key
    assert_equal "License file", bs.description
    assert !bs.primary

    # Test metadata
    assert_equal 9, item.elements.length
    assert_not_nil item.element(item.institution.date_approved_element.name)  # added automatically upon approval
    assert_not_nil item.element(item.institution.handle_uri_element.name) # added automatically when the handle is assigned
    assert_equal "Escher Lego", item.element("dc:title").string
    assert_equal "Subject 1", item.elements.select{ |e| e.name == "dc:subject"}[0].string
    assert_equal 1, item.elements.select{ |e| e.name == "dc:subject"}[0].position
    assert_equal "Subject 2", item.elements.select{ |e| e.name == "dc:subject"}[1].string
    assert_equal 2, item.elements.select{ |e| e.name == "dc:subject"}[1].position
    assert_equal "2021", item.element("dc:date:submitted").string
    assert_equal "Computer Science", item.element("thesis:degree:department").string
    assert_equal "Masters", item.element("thesis:degree:level").string
    assert_equal "Michigan Institute of Technology", item.element("thesis:degree:grantor").string
  end

  test "import_from_s3() supports a content file named contents" do
    package = File.join(PACKAGES_PATH, "valid_item_2")
    import  = imports(:uiuc_saf_new)
    upload_to_s3(package, import)
    @instance.import_from_s3(import)

    # Test the created item's immediate properties
    item = Item.order(created_at: :desc).limit(1).first
    assert_not_nil item.handle
    assert_equal Item::Stages::APPROVED, item.stage

    # Test bitstream #1
    assert_equal 2, item.bitstreams.count
    bs = item.bitstreams.where(filename: "README.txt").first
    assert_equal File.size(File.join(PACKAGES_PATH, "valid_item_2", "item_1", "README.txt")),
                 bs.length
    assert_equal Bitstream::Bundle::CONTENT, bs.bundle
    assert_equal Bitstream.permanent_key(institution_key: bs.institution.key,
                                         item_id:         bs.item_id,
                                         filename:        bs.filename),
                 bs.permanent_key
    assert_equal "Hello world", bs.description
    assert bs.primary

    # Test bitstream #2
    bs = item.bitstreams.where(filename: "license.txt").first
    assert_equal File.size(File.join(PACKAGES_PATH, "valid_item_2", "item_1", "license.txt")),
                 bs.length
    assert_equal Bitstream::Bundle::LICENSE, bs.bundle
    assert_equal Bitstream.permanent_key(institution_key: bs.institution.key,
                                         item_id:         bs.item_id,
                                         filename:        bs.filename),
                 bs.permanent_key
    assert_equal "License file", bs.description
    assert !bs.primary
  end

  test "import_from_s3() trims whitespace from metadata element values" do
    package = File.join(PACKAGES_PATH, "valid_item_2")
    import  = imports(:uiuc_saf_new)
    upload_to_s3(package, import)
    @instance.import_from_s3(import)

    item = Item.order(created_at: :desc).limit(1).first
    assert_equal "Whitespace Test", item.element("dc:title").string
    assert_equal "Subject", item.elements.select{ |e| e.name == "dc:subject"}[0].string
    assert_equal 1, item.elements.select{ |e| e.name == "dc:subject"}[0].position
    assert_equal "2021", item.element("dc:date:submitted").string
  end

  test "import_from_s3() supports uppercase content file keys" do
    package = File.join(PACKAGES_PATH, "valid_item_2")
    import  = imports(:uiuc_saf_new)
    upload_to_s3(package, import)
    @instance.import_from_s3(import)

    # Test the created item's immediate properties
    item = Item.order(created_at: :desc).limit(1).first
    assert_not_nil item.handle
    assert_equal Item::Stages::APPROVED, item.stage

    # Test bitstream #1
    assert_equal 2, item.bitstreams.count
    bs = item.bitstreams.where(filename: "README.txt").first
    assert_equal File.size(File.join(PACKAGES_PATH, "valid_item_2", "item_1", "README.txt")),
                 bs.length
    assert_equal Bitstream::Bundle::CONTENT, bs.bundle
    assert_equal Bitstream.permanent_key(institution_key: bs.institution.key,
                                         item_id:         bs.item_id,
                                         filename:        bs.filename),
                 bs.permanent_key
    assert_equal "Hello world", bs.description
    assert bs.primary

    # Test bitstream #2
    bs = item.bitstreams.where(filename: "license.txt").first
    assert_equal File.size(File.join(PACKAGES_PATH, "valid_item_2", "item_1", "license.txt")),
                 bs.length
    assert_equal Bitstream::Bundle::LICENSE, bs.bundle
    assert_equal Bitstream.permanent_key(institution_key: bs.institution.key,
                                         item_id:         bs.item_id,
                                         filename:        bs.filename),
                 bs.permanent_key
    assert_equal "License file", bs.description
    assert !bs.primary
  end

  test "import_from_s3() adds imported items to imported_items before failure" do
    package = File.join(PACKAGES_PATH, "one_invalid_item")
    import  = imports(:uiuc_saf_new)
    upload_to_s3(package, import)

    assert_raises IOError do
      @instance.import_from_s3(import)
    end

    import.reload
    imported_item = Item.order(created_at: :desc).limit(1).first
    assert_equal [{"item_id" => "item_1",
                   "handle"  => imported_item.handle.handle}],
                 import.imported_items
  end

  test "import_from_s3() adds correct mapfile lines upon success" do
    package = File.join(PACKAGES_PATH, "valid_item")
    import  = imports(:uiuc_saf_new)
    upload_to_s3(package, import)

    @instance.import_from_s3(import)
    import.reload

    # Get the created item
    item = Item.order(created_at: :desc).limit(1).first
    assert_equal [{"item_id" => "item_1",
                   "handle"  => item.handle.handle}],
                 import.imported_items
  end

  test "import_from_s3() skips already-imported items" do
    package = File.join(PACKAGES_PATH, "valid_item")
    import  = imports(:uiuc_saf_new)
    upload_to_s3(package, import)

    assert_no_changes "Item.count" do
      import.update!(imported_items: [{"item_id" => "item_1",
                                       "handle"  => "100/100"}])
      @instance.import_from_s3(import)
    end
  end

  test "import_from_s3() succeeds the import's task upon success" do
    package = File.join(PACKAGES_PATH, "valid_item")
    import  = imports(:uiuc_saf_new)
    upload_to_s3(package, import)

    @instance.import_from_s3(import)

    assert_equal Task::Status::SUCCEEDED, import.task.status
  end

  test "import_from_s3() fails the import's task failure" do
    package = File.join(PACKAGES_PATH, "one_invalid_item")
    import  = imports(:uiuc_saf_new)
    upload_to_s3(package, import)

    assert_raises IOError do
      @instance.import_from_s3(import)
    end

    assert_equal Task::Status::FAILED, import.task.status
  end


  private

  def upload_to_s3(package, import)
    PersistentStore.instance.upload_path(root_path:  package,
                                         key_prefix: import.root_key_prefix)
  end

end
