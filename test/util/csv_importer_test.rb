require 'test_helper'

class CsvImporterTest < ActiveSupport::TestCase

  setup do
    setup_s3
    setup_opensearch
    @instance = CsvImporter.new
  end

  teardown do
    teardown_s3
  end

  # import()

  test "import() raises an error for a missing id column" do
    csv = CSV.generate do |row|
      row << CsvImporter::REQUIRED_COLUMNS - %w[id]
    end
    assert_raises ArgumentError do
      @instance.import(csv:                csv,
                       submitter:          users(:example_sysadmin),
                       primary_collection: collections(:uiuc_empty))
    end
  end

  test "import() raises an error for a missing files column" do
    csv = CSV.generate do |row|
      row << CsvImporter::REQUIRED_COLUMNS - %w[files]
    end
    assert_raises ArgumentError do
      @instance.import(csv:                csv,
                       submitter:          users(:example_sysadmin),
                       primary_collection: collections(:uiuc_empty))
    end
  end

  test "import() raises an error for a missing file_descriptions column" do
    csv = CSV.generate do |row|
      row << CsvImporter::REQUIRED_COLUMNS - %w[file_descriptions]
    end
    assert_raises ArgumentError do
      @instance.import(csv:                csv,
                       submitter:          users(:example_sysadmin),
                       primary_collection: collections(:uiuc_empty))
    end
  end

  test "import() raises an error for a missing embargo_types column" do
    csv = CSV.generate do |row|
      row << CsvImporter::REQUIRED_COLUMNS - %w[embargo_types]
    end
    assert_raises ArgumentError do
      @instance.import(csv:                csv,
                       submitter:          users(:example_sysadmin),
                       primary_collection: collections(:uiuc_empty))
    end
  end

  test "import() raises an error for a missing embargo_expirations column" do
    csv = CSV.generate do |row|
      row << CsvImporter::REQUIRED_COLUMNS - %w[embargo_expirations]
    end
    assert_raises ArgumentError do
      @instance.import(csv:                csv,
                       submitter:          users(:example_sysadmin),
                       primary_collection: collections(:uiuc_empty))
    end
  end

  test "import() raises an error for a missing embargo_exempt_user_groups
  column" do
    csv = CSV.generate do |row|
      row << CsvImporter::REQUIRED_COLUMNS - %w[embargo_exempt_user_groups]
    end
    assert_raises ArgumentError do
      @instance.import(csv:                csv,
                       submitter:          users(:example_sysadmin),
                       primary_collection: collections(:uiuc_empty))
    end
  end

  test "import() raises an error for a missing embargo_reasons column" do
    csv = CSV.generate do |row|
      row << CsvImporter::REQUIRED_COLUMNS - %w[embargo_reasons]
    end
    assert_raises ArgumentError do
      @instance.import(csv:                csv,
                       submitter:          users(:example_sysadmin),
                       primary_collection: collections(:uiuc_empty))
    end
  end

  test "import() raises an error when a column is missing for an element that
  is required by the submission profile" do
    csv = CSV.generate do |row|
      row << CsvImporter::REQUIRED_COLUMNS
      row << ["+", nil, nil, nil, nil, nil, nil]
    end
    assert_raises ArgumentError do
      @instance.import(csv:                csv,
                       submitter:          users(:example_sysadmin),
                       primary_collection: collections(:uiuc_empty))
    end
  end

  test "import() raises an error when a column is blank for an element that is
  required by the submission profile" do
    csv = CSV.generate do |row|
      row << CsvImporter::REQUIRED_COLUMNS + %w[dc:title]
      row << ["+", nil, nil, nil, nil, nil, nil, ""]
    end
    assert_raises ArgumentError do
      @instance.import(csv:                csv,
                       submitter:          users(:example_sysadmin),
                       primary_collection: collections(:uiuc_empty))
    end
  end

  test "import() parses multi-value elements correctly" do
    csv = CSV.generate do |row|
      row << CsvImporter::REQUIRED_COLUMNS + %w[dc:title dc:creator]
      row << ["+", nil, nil, nil, nil, nil, nil, "Title", "Bob||Susan||Chris"]
    end
    @instance.import(csv:                csv,
                     submitter:          users(:example_sysadmin),
                     primary_collection: collections(:uiuc_empty))
    item     = Item.order(created_at: :desc).limit(1).first
    creators = item.elements.select{ |e| e.name == "dc:creator" }.map(&:string)
    assert creators.include?("Bob")
    assert creators.include?("Susan")
    assert creators.include?("Chris")
  end

  test "import() assigns positions to multi-value elements" do
    csv = CSV.generate do |row|
      row << CsvImporter::REQUIRED_COLUMNS + %w[dc:title dc:creator]
      row << ["+", nil, nil, nil, nil, nil, nil, "Title", "Bob||Susan||Chris"]
    end
    @instance.import(csv:                csv,
                     submitter:          users(:uiuc_admin),
                     primary_collection: collections(:uiuc_empty))
    item     = Item.order(created_at: :desc).limit(1).first
    creators = item.elements.
      where(registered_element: RegisteredElement.find_by(institution: institutions(:uiuc),
                                                          name:        "dc:creator")).
      order(:position).
      pluck(:position)
    assert_equal 1, creators[0]
    assert_equal 2, creators[1]
    assert_equal 3, creators[2]
  end

  test "import() creates a new item" do
    csv = CSV.generate do |row|
      row << CsvImporter::REQUIRED_COLUMNS + %w[dc:title]
      row << ["+", nil, nil, nil, nil, nil, nil, "New Item"]
    end
    @instance.import(csv:                csv,
                     submitter:          users(:example_sysadmin),
                     primary_collection: collections(:uiuc_empty))
    item = Item.order(created_at: :desc).limit(1).first
    assert_equal Item::Stages::APPROVED, item.stage
    assert_equal "New Item", item.title
  end

  test "import() raises an error for a missing file" do
    package_path = File.join(file_fixture_path, "packages", "csv", "missing_file")
    csv          = File.read(File.join(package_path, "package.csv"))
    keys         = []
    assert_raises do
      @instance.import(csv:                csv,
                       object_keys:        keys,
                       submitter:          users(:southwest_admin),
                       primary_collection: collections(:southwest_unit1_empty))
    end
  end

  test "import() attaches Bitstreams to new items" do
    package_path = File.join(file_fixture_path, "packages", "csv", "valid_items")
    csv          = File.read(File.join(package_path, "package.csv"))
    keys         = []
    PersistentStore.instance.upload_path(root_path:     package_path,
                                         key_prefix:    "tmp",
                                         uploaded_keys: keys)

    @instance.import(csv:                csv,
                     object_keys:        keys,
                     submitter:          users(:southwest_admin),
                     primary_collection: collections(:southwest_unit1_empty))
    item       = Item.order(created_at: :desc).limit(1).first
    bitstreams = item.bitstreams
    assert_equal 2, bitstreams.count
    bitstream = bitstreams.find{ |b| b.filename == "hello.txt" }
    assert_equal 28, bitstream.length
    assert_equal Bitstream.permanent_key(institution_key: item.institution.key,
                                         item_id:         item.id,
                                         filename:        bitstream.filename),
                 bitstream.permanent_key
    assert_equal "Hello world", bitstream.description
    assert bitstream.primary
    assert_equal 0, bitstream.bundle_position
  end

  test "import() attaches Bitstreams to existing items" do
    item = items(:southwest_unit1_collection1_item1)
    csv  = CSV.generate do |row|
      row << CsvImporter::REQUIRED_COLUMNS + %w[dc:title]
      row << [item.id, "tmp/escher_lego.png", nil, nil, nil, nil, nil, "Title"]
    end

    file = file_fixture("escher_lego.png")
    S3Client.instance.put_object(bucket: PersistentStore::BUCKET,
                                 key:    "tmp/escher_lego.png",
                                 body:   File.new(file))

    assert_difference "Bitstream.count", 1 do
      @instance.import(csv:                csv,
                       object_keys:        ["tmp/escher_lego.png"],
                       submitter:          users(:southwest_admin),
                       primary_collection: collections(:southwest_unit1_empty))
    end
  end

  test "import() marks the first attached Bitstream as primary" do
    item  = items(:southwest_unit1_collection1_item1)
    item.bitstreams.destroy_all
    files = %w[gull.jpg pooh.jpg]
    csv   = CSV.generate do |row|
      row << CsvImporter::REQUIRED_COLUMNS + %w[dc:title]
      row << [item.id, files.map{ |f| "tmp/#{f}" }.join("||"), nil, nil, nil,
              nil, nil, "Title"]
    end

    files.each do |file|
      fixture = file_fixture(file)
      S3Client.instance.put_object(bucket: PersistentStore::BUCKET,
                                   key:    "tmp/#{file}",
                                   body:   File.new(fixture))
    end

    @instance.import(csv:                csv,
                     object_keys:        files.map{ |f| "tmp/#{f}" },
                     submitter:          users(:southwest_admin),
                     primary_collection: collections(:southwest_unit1_empty))

    item.reload
    b = item.bitstreams.where(filename: "gull.jpg").first
    assert b.primary?
    b = item.bitstreams.where(filename: "pooh.jpg").first
    assert !b.primary?
  end

  test "import() sets bundle positions on attached bitstreams" do
    item  = items(:southwest_unit1_collection1_item1)
    item.bitstreams.destroy_all
    files = %w[gull.jpg pooh.jpg]
    csv   = CSV.generate do |row|
      row << CsvImporter::REQUIRED_COLUMNS + %w[dc:title]
      row << [item.id, files.map{ |f| "tmp/#{f}" }.join("||"), nil, nil, nil,
              nil, nil, "Title"]
    end

    files.each do |file|
      fixture = file_fixture(file)
      S3Client.instance.put_object(bucket: PersistentStore::BUCKET,
                                   key:    "tmp/#{file}",
                                   body:   File.new(fixture))
    end

    @instance.import(csv:                csv,
                     object_keys:        files.map{ |f| "tmp/#{f}" },
                     submitter:          users(:southwest_admin),
                     primary_collection: collections(:southwest_unit1_empty))

    item.reload
    item.bitstreams.order(:bundle_position).each_with_index do |bs, index|
      assert_equal index, bs.bundle_position
    end
  end

  test "import() ignores files that are already attached to an item" do
    item  = items(:southwest_unit1_collection1_item1)
    csv   = CSV.generate do |row|
      row << CsvImporter::REQUIRED_COLUMNS + %w[dc:title]
      row << [item.id, "approved.png", nil, nil, nil, nil, nil, "Title"]
    end
    assert_no_difference "Bitstream.count" do
      @instance.import(csv:                csv,
                       object_keys:        ["this shouldn't be used"],
                       submitter:          users(:southwest_admin),
                       primary_collection: collections(:southwest_unit1_empty))
    end
  end

  test "import() attaches correct Embargoes to items" do
    package_path = File.join(file_fixture_path, "packages", "csv", "valid_items")
    csv          = File.read(File.join(package_path, "package.csv"))

    @instance.import(csv:                csv,
                     submitter:          users(:southwest_admin),
                     primary_collection: collections(:southwest_unit1_empty))
    item       = Item.order(created_at: :desc).limit(1).first

    assert_equal 2, item.embargoes.count
    e = item.embargoes.find{ |e| e.kind == Embargo::Kind::ALL_ACCESS }
    assert_equal Time.parse("2045-02-05"), e.expires_at
    assert_equal ["sysadmin"], e.user_groups.map(&:key)
    assert_equal "Reason 1", e.reason

    e = item.embargoes.find{ |e| e.kind == Embargo::Kind::DOWNLOAD }
    assert_equal Time.parse("2055-03-10"), e.expires_at
    assert_equal "Reason 2", e.reason
  end

  test "import() adds created items to the imported_items array" do
    csv = CSV.generate do |row|
      row << CsvImporter::REQUIRED_COLUMNS + %w[dc:title]
      row << ["+", nil, nil, nil, nil, nil, nil, "New Item"]
    end
    imported_items = []
    @instance.import(csv:                csv,
                     submitter:          users(:example_sysadmin),
                     primary_collection: collections(:uiuc_empty),
                     imported_items:     imported_items)
    assert_equal 1, imported_items.length
  end

  test "import() raises an error when an unrecognized element is present in the
  CSV" do
    csv = CSV.generate do |row|
      row << CsvImporter::REQUIRED_COLUMNS + %w[bogus:bogus]
      row << ["+", nil, nil, nil, nil, nil, nil, "New Value"]
    end
    assert_raises ArgumentError do
      @instance.import(csv:                csv,
                       submitter:          users(:example_sysadmin),
                       primary_collection: collections(:uiuc_empty))
    end
  end

  test "import() raises an error when a non-existent item ID is present in the
  CSV" do
    csv = CSV.generate do |row|
      row << CsvImporter::REQUIRED_COLUMNS + %w[dc:title]
      row << ["999999", nil, nil, nil, nil, nil, "New Value"]
    end
    assert_raises ActiveRecord::RecordNotFound do
      @instance.import(csv:                csv,
                       submitter:          users(:example_sysadmin),
                       primary_collection: collections(:uiuc_empty))
    end
  end

  test "import() raises an error for a blank item ID cell" do
    csv = CSV.generate do |row|
      row << CsvImporter::REQUIRED_COLUMNS + %w[dc:title]
      row << [nil, nil, nil, nil, nil, nil, "New Value"]
    end
    assert_raises do
      @instance.import(csv:                csv,
                       submitter:          users(:example_sysadmin),
                       primary_collection: collections(:uiuc_empty))
    end
  end

  test "import() updates an existing item" do
    item = items(:uiuc_item1)
    csv = CSV.generate do |row|
      row << CsvImporter::REQUIRED_COLUMNS + %w[dc:title]
      row << [item.id, nil, nil, nil, nil, nil, nil, "New Title"]
    end
    @instance.import(csv:                csv,
                     submitter:          users(:example_sysadmin),
                     primary_collection: collections(:uiuc_empty))
    item.reload
    assert_equal "New Title", item.title
  end

  test "import() deletes elements corresponding to blank element values" do
    item = items(:uiuc_described)
    csv = CSV.generate do |row|
      row << CsvImporter::REQUIRED_COLUMNS + %w[dc:title dc:subject]
      row << [item.id, nil, nil, nil, nil, nil, nil, "Title", ""]
    end
    @instance.import(csv:                csv,
                     submitter:          users(:example_sysadmin),
                     primary_collection: collections(:uiuc_empty))
    item.reload
    assert_nil item.element("dc:subject")
  end

  test "import() does not modify elements other than those contained in the
  CSV" do
    item = items(:uiuc_described)
    csv = CSV.generate do |row|
      row << CsvImporter::REQUIRED_COLUMNS + %w[dc:title]
      row << [item.id, nil, nil, nil, nil, nil, nil, "New Title"]
    end
    @instance.import(csv:                csv,
                     submitter:          users(:example_sysadmin),
                     primary_collection: collections(:uiuc_empty))
    item.reload
    assert_equal "New Title", item.element("dc:title").string      # new value
    assert_equal "Some subject", item.element("dc:subject").string # existing value
  end

  test "import() succeeds the import's task upon success" do
    item = items(:uiuc_described)
    csv = CSV.generate do |row|
      row << CsvImporter::REQUIRED_COLUMNS + %w[dc:title]
      row << [item.id, nil, nil, nil, nil, nil, nil, "New Title"]
    end
    task = Task.create!(name: "TestImport", status_text: "Lorem Ipsum")
    @instance.import(csv:                csv,
                     submitter:          users(:example_sysadmin),
                     primary_collection: collections(:uiuc_empty),
                     task:               task)
    assert_equal Task::Status::SUCCEEDED, task.status
    assert_equal 1, task.percent_complete
  end

  test "import() fails the import's task upon error" do
    item = items(:uiuc_described)
    csv = CSV.generate do |row|
      row << CsvImporter::REQUIRED_COLUMNS + %w[bogus:bogus]
      row << [item.id, nil, nil, nil, nil, nil, "Bogus element value"]
    end
    task = Task.create!(name: "TestImport", status_text: "Lorem Ipsum")
    assert_raises do
      @instance.import(csv:                csv,
                       submitter:          users(:example_sysadmin),
                       primary_collection: collections(:uiuc_empty),
                       task:               task)
    end
    assert_equal Task::Status::FAILED, task.status
    assert_equal 0, task.percent_complete
  end

  # import_from_s3()

  test "import_from_s3() sets the import format" do
    csv    = file_fixture("csv/new.csv")
    import = imports(:uiuc_csv_file_new)
    upload_to_s3(csv, import)
    @instance.import_from_s3(import, users(:example_sysadmin))

    assert_equal Import::Format::CSV_FILE, import.format
  end

  test "import_from_s3() creates correct items" do
    csv    = file_fixture("csv/new.csv")
    import = imports(:uiuc_csv_file_new)
    upload_to_s3(csv, import)
    @instance.import_from_s3(import, users(:example_sysadmin))

    # Test the created item's immediate properties
    item = Item.order(created_at: :desc).limit(1).first
    assert_not_nil item.handle
    assert_equal Item::Stages::APPROVED, item.stage

    # Test metadata
    assert_equal 4, item.elements.length
    assert_not_nil item.element(item.institution.handle_uri_element.name) # added automatically when the handle is assigned
    assert_equal "New CSV Item", item.element("dc:title").string
  end

  test "import_from_s3() fails the import's task upon error" do
    csv    = file_fixture("csv/illegal_element.csv")
    import = imports(:uiuc_csv_file_new)
    upload_to_s3(csv, import)

    assert_raises do
      @instance.import_from_s3(import, users(:example_sysadmin))
    end

    assert_equal Task::Status::FAILED, import.task.status
  end

  test "import_from_s3() succeeds the import's task upon success" do
    csv    = file_fixture("csv/new.csv")
    import = imports(:uiuc_csv_file_new)
    upload_to_s3(csv, import)

    @instance.import_from_s3(import, users(:example_sysadmin))

    assert_equal Task::Status::SUCCEEDED, import.task.status
  end


  private

  def upload_to_s3(file, import)
    PersistentStore.instance.put_object(key:  import.root_key_prefix + file.basename.to_s,
                                        file: file)
  end

end
