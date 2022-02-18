require 'test_helper'

class CsvImporterTest < ActiveSupport::TestCase

  setup do
    setup_s3
    setup_elasticsearch
    @instance = CsvImporter.new
  end

  teardown do
    teardown_s3
  end

  # import()

  test "import() handles multi-value elements correctly" do
    csv = CSV.generate do |row|
      row << ["id", "dc:creator"]
      row << ["+", "Bob||Susan||Chris"]
    end
    @instance.import(csv:                csv,
                     submitter:          users(:local_sysadmin),
                     primary_collection: collections(:empty))
    item     = Item.order(created_at: :desc).limit(1).first
    creators = item.elements.select{ |e| e.name == "dc:creator" }.map(&:string)
    assert creators.include?("Bob")
    assert creators.include?("Susan")
    assert creators.include?("Chris")
  end

  test "import() creates a new item" do
    csv = CSV.generate do |row|
      row << ["id", "dc:title"]
      row << ["+" ,"New Item"]
    end
    @instance.import(csv:                csv,
                     submitter:          users(:local_sysadmin),
                     primary_collection: collections(:empty))
    item = Item.order(created_at: :desc).limit(1).first
    assert_equal Item::Stages::SUBMITTED, item.stage
    assert_equal "New Item", item.title
  end

  test "import() adds created items to the imported_items array" do
    csv = CSV.generate do |row|
      row << ["id", "dc:title"]
      row << ["+" ,"New Item"]
    end
    imported_items = []
    @instance.import(csv:                csv,
                     submitter:          users(:local_sysadmin),
                     primary_collection: collections(:empty),
                     imported_items:     imported_items)
    assert_equal 1, imported_items.length
  end

  test "import() raises an error when an unrecognized element is present in the
  CSV" do
    csv = CSV.generate do |row|
      row << ["id", "dc:bogus"]
      row << ["+", "New Value"]
    end
    assert_raises ArgumentError do
      @instance.import(csv:                csv,
                       submitter:          users(:local_sysadmin),
                       primary_collection: collections(:empty))
    end
  end

  test "import() raises an error when a non-existent item ID is present in the
  CSV" do
    csv = CSV.generate do |row|
      row << ["id", "dc:title"]
      row << ["999999", "New Value"]
    end
    assert_raises ActiveRecord::RecordNotFound do
      @instance.import(csv:                csv,
                       submitter:          users(:local_sysadmin),
                       primary_collection: collections(:empty))
    end
  end

  test "import() updates an existing item" do
    item = items(:item1)
    csv = CSV.generate do |row|
      row << ["id", "dc:title"]
      row << ["#{item.id}", "New Title"]
    end
    @instance.import(csv:                csv,
                     submitter:          users(:local_sysadmin),
                     primary_collection: collections(:empty))
    item.reload
    assert_equal "New Title", item.title
  end

  test "import() deletes elements corresponding to blank element values" do
    item = items(:described)
    csv = CSV.generate do |row|
      row << ["id", "dc:subject"]
      row << ["#{item.id}", ""]
    end
    @instance.import(csv:                csv,
                     submitter:          users(:local_sysadmin),
                     primary_collection: collections(:empty))
    item.reload
    assert_nil item.element("dc:subject")
  end

  test "import() does not modify elements other than those contained in the
  CSV" do
    item = items(:described)
    csv = CSV.generate do |row|
      row << ["id", "dc:title"]
      row << ["#{item.id}", "New Title"]
    end
    @instance.import(csv:                csv,
                     submitter:          users(:local_sysadmin),
                     primary_collection: collections(:empty))
    item.reload
    assert_equal "New Title", item.element("dc:title").string      # new value
    assert_equal "Some subject", item.element("dc:subject").string # existing value
  end

  # import_from_s3()

  test "import_from_s3() sets the import kind" do
    csv    = file_fixture("csv/new.csv")
    import = imports(:csv_new)
    upload_to_s3(csv, import)
    @instance.import_from_s3(import, users(:local_sysadmin))

    assert_equal Import::Kind::CSV, import.kind
  end

  test "import_from_s3() creates correct items" do
    csv    = file_fixture("csv/new.csv")
    import = imports(:csv_new)
    upload_to_s3(csv, import)
    @instance.import_from_s3(import, users(:local_sysadmin))

    # Test the created item's immediate properties
    item = Item.order(created_at: :desc).limit(1).first
    assert_not_nil item.handle
    assert item.discoverable
    assert_equal Item::Stages::APPROVED, item.stage

    # Test metadata
    assert_equal 5, item.elements.length
    assert_not_nil item.element("dcterms:available")  # added automatically upon approval
    assert_not_nil item.element("dcterms:identifier") # added automatically when the handle is assigned
    assert_equal "New CSV Item", item.element("dc:title").string
  end

  test "import_from_s3() sets the import status to succeeded upon success" do
    csv    = file_fixture("csv/new.csv")
    import = imports(:csv_new)
    upload_to_s3(csv, import)
    @instance.import_from_s3(import, users(:local_sysadmin))

    import.reload
    assert_equal Import::Status::SUCCEEDED, import.status
  end

  test "import_from_s3() sets the import status to failed upon error" do
    csv    = file_fixture("csv/illegal_element.csv")
    import = imports(:csv_new)
    upload_to_s3(csv, import)

    assert_raises do
      @instance.import_from_s3(import, users(:local_sysadmin))
    end

    import.reload
    assert_equal Import::Status::FAILED, import.status
  end


  private

  def upload_to_s3(file, import)
    S3Client.instance.put_object(bucket: ::Configuration.instance.aws[:bucket],
                                 key:    import.root_key_prefix + file.basename.to_s,
                                 body:   file.read)
  end

end
