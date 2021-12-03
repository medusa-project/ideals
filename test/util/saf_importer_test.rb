require 'test_helper'

class SafImporterTest < ActiveSupport::TestCase

  PACKAGES_PATH = File.join(Rails.root, "test", "fixtures", "saf_packages")

  setup do
    setup_s3
    setup_elasticsearch
    @instance = SafImporter.new
  end

  # import()

  test "import() raises an error for a missing content file" do
    package = File.join(PACKAGES_PATH, "missing_content_file")
    assert_raises IOError do
      @instance.import(pathname:           package,
                       primary_collection: collections(:collection1),
                       mapfile_path:       Tempfile.new("test"))
    end
  end

  test "import() raises an error for a missing file component on a line of the
  content file" do
    package = File.join(PACKAGES_PATH, "missing_file_on_content_file_line")
    assert_raises IOError do
      @instance.import(pathname:           package,
                       primary_collection: collections(:collection1),
                       mapfile_path:       Tempfile.new("test"))
    end
  end

  test "import() raises an error for an illegal flag in a content file" do
    package = File.join(PACKAGES_PATH, "illegal_content_file_flag")
    assert_raises IOError do
      @instance.import(pathname:           package,
                       primary_collection: collections(:collection1),
                       mapfile_path:       Tempfile.new("test"))
    end
  end

  test "import() raises an error for a missing file that is present in the
  content file" do
    package = File.join(PACKAGES_PATH, "missing_file")
    assert_raises IOError do
      @instance.import(pathname:           package,
                       primary_collection: collections(:collection1),
                       mapfile_path:       Tempfile.new("test"))
    end
  end

  test "import() raises an error for a missing dublin_core.xml file" do
    package = File.join(PACKAGES_PATH, "missing_dublin_core")
    assert_raises IOError do
      @instance.import(pathname:           package,
                       primary_collection: collections(:collection1),
                       mapfile_path:       Tempfile.new("test"))
    end
  end

  test "import() raises an error when encountering a registered element not
  present in the registry" do
    package = File.join(PACKAGES_PATH, "illegal_metadata_element")
    assert_raises IOError do
      @instance.import(pathname:           package,
                       primary_collection: collections(:collection1),
                       mapfile_path:       Tempfile.new("test"))
    end
  end

  test "import() creates correct items" do
    package = File.join(PACKAGES_PATH, "valid_item")
    @instance.import(pathname:           package,
                     primary_collection: collections(:collection1),
                     mapfile_path:       Tempfile.new("test"))

    # Test the created item's immediate properties
    item = Item.order(created_at: :desc).limit(1).first
    assert_not_nil item.handle
    assert item.discoverable
    assert_equal Item::Stages::APPROVED, item.stage

    # Test bitstream #1
    assert_equal 2, item.bitstreams.count
    bs = item.bitstreams.where(original_filename: "hello.txt").first
    assert_equal File.size(File.join(PACKAGES_PATH, "valid_item", "item_1", "hello.txt")),
                 bs.length
    assert_equal Bitstream::Bundle::CONTENT, bs.bundle
    assert_equal Bitstream.permanent_key(bs.item_id, bs.original_filename),
                 bs.permanent_key
    assert_equal "Hello world", bs.description
    assert bs.primary

    # Test bitstream #2
    bs = item.bitstreams.where(original_filename: "license.txt").first
    assert_equal File.size(File.join(PACKAGES_PATH, "valid_item", "item_1", "license.txt")),
                 bs.length
    assert_equal Bitstream::Bundle::LICENSE, bs.bundle
    assert_equal Bitstream.permanent_key(bs.item_id, bs.original_filename),
                 bs.permanent_key
    assert_equal "License file", bs.description
    assert !bs.primary

    # Test metadata
    assert_equal 7, item.elements.length
    assert_not_nil item.element("dcterms:available")  # added automatically upon approval
    assert_not_nil item.element("dcterms:identifier") # added automatically when the handle is assigned
    assert_equal "Escher Lego", item.element("dc:title").string
    assert_equal "2021", item.element("dc:date:submitted").string
    assert_equal "Computer Science", item.element("etd:degree:department").string
    assert_equal "Masters", item.element("etd:degree:level").string
    assert_equal "Michigan Institute of Technology", item.element("etd:degree:grantor").string
  end

  test "import() adds correct mapfile lines upon failure" do
    package = File.join(PACKAGES_PATH, "one_invalid_item")
    Tempfile.open("test") do |mapfile|
      assert_raises IOError do
        @instance.import(pathname:           package,
                         primary_collection: collections(:collection1),
                         mapfile_path:       mapfile.path)
      end
      contents = mapfile.read
      assert_match /^item_1\t\d+\/\d+\b/, contents
    end
  end

  test "import() adds correct mapfile lines upon success" do
    package       = File.join(PACKAGES_PATH, "valid_item")
    Tempfile.open("test") do |mapfile|
      @instance.import(pathname:           package,
                       primary_collection: collections(:collection1),
                       mapfile_path:       mapfile)
      # Get the created item
      item = Item.order(created_at: :desc).limit(1).first
      assert_equal "item_1\t#{item.handle.handle}\n", mapfile.read
    end
  end

  test "import() skips items present in the mapfile" do
    package = File.join(PACKAGES_PATH, "valid_item")
    assert_no_changes "Item.count" do
      mapfile = Tempfile.new("test")
      begin
        File.open(mapfile.path, "w") do |file|
          file.write("item_1\t100/100\n")
        end
        @instance.import(pathname:           package,
                         primary_collection: collections(:collection1),
                         mapfile_path:       mapfile)
      ensure
        mapfile.close
        mapfile.unlink
      end
    end
  end

end
