require 'test_helper'

class CsvImporterTest < ActiveSupport::TestCase

  setup do
    setup_opensearch
    setup_s3
    @instance = CsvImporter.new
  end

  teardown do
    teardown_s3
  end

  # import()

  test "import() raises an error for a missing pathname argument" do
    assert_raises ArgumentError do
      @instance.import(pathname:           nil,
                       file_paths:         [],
                       submitter:          users(:southwest_sysadmin),
                       primary_collection: collections(:southeast_empty))
    end
  end

  test "import() raises an error for a pathname that does not exist" do
    assert_raises ArgumentError do
      @instance.import(pathname:           "/bogus/bogus/bogus.csv",
                       file_paths:         [],
                       submitter:          users(:southwest_sysadmin),
                       primary_collection: collections(:southeast_empty))
    end
  end

  test "import() raises an error for a missing submitter argument" do
    csv = CSV.generate do |row|
      row << CsvImporter::REQUIRED_COLUMNS - %w[files]
    end
    file = Tempfile.new(%w[test, .csv])
    File.write(file, csv)

    assert_raises ArgumentError do
      @instance.import(pathname:           file.path,
                       file_paths:         [],
                       submitter:          nil,
                       primary_collection: collections(:southeast_empty))
    end
  ensure
    file.unlink
  end

  test "import() raises an error when the first handle in the
  collection_handles column is different from the primary_collection
  argument" do
    csv = CSV.generate do |row|
      row << CsvImporter::REQUIRED_COLUMNS
      row << ["+", nil, nil, handles(:southeast_collection2).to_s,
              nil, nil, nil, nil, nil, nil, "Title"]
    end
    file = Tempfile.new(%w[test, .csv])
    File.write(file, csv)

    assert_raises ArgumentError do
      @instance.import(pathname:           file.path,
                       file_paths:         [],
                       submitter:          users(:southeast_admin),
                       primary_collection: collections(:southeast_collection1))
    end
  ensure
    file.unlink
  end

  test "import() raises an error for a missing id column" do
    csv = CSV.generate do |row|
      row << CsvImporter::REQUIRED_COLUMNS - %w[id]
    end
    file = Tempfile.new(%w[test, .csv])
    File.write(file, csv)

    assert_raises ArgumentError do
      @instance.import(pathname:           file.path,
                       submitter:          users(:southwest_sysadmin),
                       primary_collection: collections(:southeast_empty))
    end
  ensure
    file.unlink
  end

  test "import() raises an error for a missing handle column" do
    csv = CSV.generate do |row|
      row << CsvImporter::REQUIRED_COLUMNS - %w[handle]
    end
    file = Tempfile.new(%w[test, .csv])
    File.write(file, csv)

    assert_raises ArgumentError do
      @instance.import(pathname:           file.path,
                       submitter:          users(:southwest_sysadmin),
                       primary_collection: collections(:southeast_empty))
    end
  ensure
    file.unlink
  end

  test "import() raises an error for a missing stage column" do
    csv = CSV.generate do |row|
      row << CsvImporter::REQUIRED_COLUMNS - %w[stage]
    end
    file = Tempfile.new(%w[test, .csv])
    File.write(file, csv)

    assert_raises ArgumentError do
      @instance.import(pathname:           file.path,
                       submitter:          users(:southwest_sysadmin),
                       primary_collection: collections(:southeast_empty))
    end
  ensure
    file.unlink
  end

  test "import() raises an error for a missing collection_handles column" do
    csv = CSV.generate do |row|
      row << CsvImporter::REQUIRED_COLUMNS - %w[collection_handles]
    end
    file = Tempfile.new(%w[test, .csv])
    File.write(file, csv)

    assert_raises ArgumentError do
      @instance.import(pathname:           file.path,
                       submitter:          users(:southwest_sysadmin),
                       primary_collection: collections(:southeast_empty))
    end
  ensure
    file.unlink
  end

  test "import() raises an error for a missing files column" do
    csv = CSV.generate do |row|
      row << CsvImporter::REQUIRED_COLUMNS - %w[files]
    end
    file = Tempfile.new(%w[test, .csv])
    File.write(file, csv)

    assert_raises ArgumentError do
      @instance.import(pathname:           file.path,
                       submitter:          users(:southwest_sysadmin),
                       primary_collection: collections(:southeast_empty))
    end
  ensure
    file.unlink
  end

  test "import() raises an error for a missing file_descriptions column" do
    csv = CSV.generate do |row|
      row << CsvImporter::REQUIRED_COLUMNS - %w[file_descriptions]
    end
    file = Tempfile.new(%w[test, .csv])
    File.write(file, csv)

    assert_raises ArgumentError do
      @instance.import(pathname:           file.path,
                       submitter:          users(:southwest_sysadmin),
                       primary_collection: collections(:southeast_empty))
    end
  ensure
    file.unlink
  end

  test "import() raises an error for a missing embargo_types column" do
    csv = CSV.generate do |row|
      row << CsvImporter::REQUIRED_COLUMNS - %w[embargo_types]
    end
    file = Tempfile.new(%w[test, .csv])
    File.write(file, csv)

    assert_raises ArgumentError do
      @instance.import(pathname:           file.path,
                       submitter:          users(:southwest_sysadmin),
                       primary_collection: collections(:southeast_empty))
    end
  ensure
    file.unlink
  end

  test "import() raises an error for a missing embargo_expirations column" do
    csv = CSV.generate do |row|
      row << CsvImporter::REQUIRED_COLUMNS - %w[embargo_expirations]
    end
    file = Tempfile.new(%w[test, .csv])
    File.write(file, csv)

    assert_raises ArgumentError do
      @instance.import(pathname:           file.path,
                       submitter:          users(:southwest_sysadmin),
                       primary_collection: collections(:southeast_empty))
    end
  ensure
    file.unlink
  end

  test "import() raises an error for a missing embargo_exempt_user_groups
  column" do
    csv = CSV.generate do |row|
      row << CsvImporter::REQUIRED_COLUMNS - %w[embargo_exempt_user_groups]
    end
    file = Tempfile.new(%w[test, .csv])
    File.write(file, csv)

    assert_raises ArgumentError do
      @instance.import(pathname:           file.path,
                       submitter:          users(:southwest_sysadmin),
                       primary_collection: collections(:southeast_empty))
    end
  ensure
    file.unlink
  end

  test "import() raises an error for a missing embargo_reasons column" do
    csv = CSV.generate do |row|
      row << CsvImporter::REQUIRED_COLUMNS - %w[embargo_reasons]
    end
    file = Tempfile.new(%w[test, .csv])
    File.write(file, csv)

    assert_raises ArgumentError do
      @instance.import(pathname:           file.path,
                       submitter:          users(:southwest_sysadmin),
                       primary_collection: collections(:southeast_empty))
    end
  ensure
    file.unlink
  end

  test "import() raises an error when a column is missing for an element that
  is required by the submission profile" do
    csv = CSV.generate do |row|
      row << CsvImporter::REQUIRED_COLUMNS
      row << ["+", nil, nil, nil, nil, nil, nil, nil, nil, nil]
    end
    file = Tempfile.new(%w[test, .csv])
    File.write(file, csv)

    assert_raises ArgumentError do
      @instance.import(pathname:           file.path,
                       submitter:          users(:southwest_sysadmin),
                       primary_collection: collections(:southeast_empty))
    end
  ensure
    file.unlink
  end

  test "import() raises an error when a column is blank for an element that is
  required by the submission profile" do
    csv = CSV.generate do |row|
      row << CsvImporter::REQUIRED_COLUMNS + %w[dc:title]
      row << ["+", nil, nil, nil, nil, nil, nil, nil, nil, nil, ""]
    end
    file = Tempfile.new(%w[test, .csv])
    File.write(file, csv)

    assert_raises ArgumentError do
      @instance.import(pathname:           file.path,
                       submitter:          users(:southwest_sysadmin),
                       primary_collection: collections(:southeast_empty))
    end
  ensure
    file.unlink
  end

  test "import() parses multi-value elements correctly" do
    csv = CSV.generate do |row|
      row << CsvImporter::REQUIRED_COLUMNS + %w[dc:title dc:creator]
      row << ["+", nil, nil, nil, nil, nil, nil, nil, nil, nil, "Title", "Bob||Susan||Chris"]
    end
    file = Tempfile.new(%w[test, .csv])
    File.write(file, csv)

    @instance.import(pathname:           file.path,
                     file_paths:         [],
                     submitter:          users(:southwest_sysadmin),
                     primary_collection: collections(:southeast_empty))
    item     = Item.order(created_at: :desc).limit(1).first
    creators = item.elements.select{ |e| e.name == "dc:creator" }.map(&:string)
    assert creators.include?("Bob")
    assert creators.include?("Susan")
    assert creators.include?("Chris")
  ensure
    file.unlink
  end

  test "import() assigns positions to multi-value elements" do
    csv = CSV.generate do |row|
      row << CsvImporter::REQUIRED_COLUMNS + %w[dc:title dc:creator]
      row << ["+", nil, nil, nil, nil, nil, nil, nil, nil, nil, "Title", "Bob||Susan||Chris"]
    end
    file = Tempfile.new(%w[test, .csv])
    File.write(file, csv)

    @instance.import(pathname:           file.path,
                     file_paths:         [],
                     submitter:          users(:southeast_admin),
                     primary_collection: collections(:southeast_empty))
    item     = Item.order(created_at: :desc).limit(1).first
    creators = item.elements.
      where(registered_element: RegisteredElement.find_by(institution: institutions(:southeast),
                                                          name:        "dc:creator")).
      order(:position).
      pluck(:position)
    assert_equal 1, creators[0]
    assert_equal 2, creators[1]
    assert_equal 3, creators[2]
  ensure
    file.unlink
  end

  test "import() creates a new item" do
    csv = CSV.generate do |row|
      row << CsvImporter::REQUIRED_COLUMNS + %w[dc:title]
      row << ["+", nil, nil, nil, nil, nil, nil, nil, nil, nil, "New Item"]
    end
    file = Tempfile.new(%w[test, .csv])
    File.write(file, csv)

    @instance.import(pathname:           file.path,
                     file_paths:         [],
                     submitter:          users(:southwest_sysadmin),
                     primary_collection: collections(:southeast_empty))
    item = Item.order(created_at: :desc).limit(1).first
    assert_equal Item::Stages::APPROVED, item.stage
    assert_equal "New Item", item.title
  ensure
    file.unlink
  end

  test "import() raises an error for a missing file" do
    package_path = File.join(file_fixture_path, "packages", "csv", "missing_file")
    csv_path     = File.join(package_path, "package.csv")
    files        = []
    assert_raises do
      @instance.import(pathname:           csv_path,
                       file_paths:         files,
                       submitter:          users(:southwest_admin),
                       primary_collection: collections(:southwest_unit1_empty))
    end
  end

  test "import() places a new item into the collections given in the
  collection_handles column" do
    collection1 = collections(:southeast_collection1)
    collection2 = collections(:southeast_collection2)
    csv = CSV.generate do |row|
      row << CsvImporter::REQUIRED_COLUMNS + %w[dc:title dc:creator]
      row << ["+", nil, nil,
              [collection1.handle.to_s, collection2.handle.to_s].join(CsvImporter::MULTI_VALUE_DELIMITER),
              nil, nil, nil, nil, nil, nil, "Title", "Bob"]
    end
    file = Tempfile.new(%w[test, .csv])
    File.write(file, csv)

    @instance.import(pathname:           file.path,
                     file_paths:         [],
                     submitter:          users(:southeast_admin),
                     primary_collection: collection1)
    item = Item.order(created_at: :desc).limit(1).first
    assert_equal 2, item.collection_item_memberships.count
    assert_equal collection1, item.effective_primary_collection
    assert item.collections.include?(collection2)
  ensure
    file.unlink
  end

  test "import() moves an existing item into the collections given in the
  collection_handles column" do
    item            = items(:southeast_approved)
    item.collection_item_memberships.destroy_all
    new_collection1 = collections(:southeast_collection1)
    new_collection2 = collections(:southeast_collection2)

    csv = CSV.generate do |row|
      row << CsvImporter::REQUIRED_COLUMNS + %w[dc:title dc:creator]
      row << [item.id, nil, nil,
              [new_collection1.handle.to_s, new_collection2.handle.to_s].join(CsvImporter::MULTI_VALUE_DELIMITER),
              nil, nil, nil, nil, nil, nil, "Title", "Bob"]
    end
    file = Tempfile.new(%w[test, .csv])
    File.write(file, csv)

    @instance.import(pathname:           file.path,
                     file_paths:         [],
                     submitter:          users(:southeast_admin),
                     primary_collection: new_collection1)
    item.reload
    assert_equal new_collection1, item.effective_primary_collection
    assert item.collections.include?(new_collection2)
  ensure
    file.unlink
  end

  test "import() raises an error when asked to place a new item into a
  collection of which the submitter is not a manager" do
    collection = collections(:southeast_collection1)
    csv = CSV.generate do |row|
      row << CsvImporter::REQUIRED_COLUMNS + %w[dc:title dc:creator]
      row << ["+", nil, nil, collection.handle.to_s,
              nil, nil, nil, nil, nil, nil, "Title", "Bob"]
    end
    file = Tempfile.new(%w[test, .csv])
    File.write(file, csv)

    assert_raises ArgumentError do
      @instance.import(pathname:           file.path,
                       file_paths:         [],
                       submitter:          users(:southeast),
                       primary_collection: collection)
    end
  ensure
    file.unlink
  end

  test "import() raises an error when asked to move an existing item into a
  collection of which the submitter is not a manager" do
    item               = items(:southeast_approved)
    current_collection = item.effective_primary_collection
    new_collection     = collections(:southeast_empty)
    assert_not_equal new_collection, current_collection

    csv = CSV.generate do |row|
      row << CsvImporter::REQUIRED_COLUMNS + %w[dc:title dc:creator]
      row << ["+", nil, nil, new_collection.handle.to_s,
              nil, nil, nil, nil, nil, nil, "Title", "Bob"]
    end
    file = Tempfile.new(%w[test, .csv])
    File.write(file, csv)

    assert_raises ArgumentError do
      @instance.import(pathname:           file.path,
                       file_paths:         [],
                       submitter:          users(:southeast),
                       primary_collection: new_collection)
    end
  ensure
    file.unlink
  end

  test "import() attaches Bitstreams to new items" do
    package_path = File.join(file_fixture_path, "packages", "csv", "valid_items")
    csv_path     = File.join(package_path, "package.csv")
    files        = Dir.glob(package_path + "/**/*").select{ |n| File.file?(n) }

    @instance.import(pathname:           csv_path,
                     file_paths:         files,
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
      row << [item.id, nil, nil, nil, "escher_lego.png", nil, nil, nil, nil, nil, "Title"]
    end
    files = [file_fixture("escher_lego.png").to_s]
    file  = Tempfile.new(%w[test, .csv])
    File.write(file, csv)

    assert_difference "Bitstream.count", 1 do
      @instance.import(pathname:           file.path,
                       file_paths:         files,
                       submitter:          users(:southwest_admin),
                       primary_collection: collections(:southwest_unit1_empty))
    end
  ensure
    file.unlink
  end

  test "import() marks the first attached Bitstream as primary" do
    item  = items(:southwest_unit1_collection1_item1)
    item.bitstreams.destroy_all
    files = %w[gull.jpg pooh.jpg]
    csv   = CSV.generate do |row|
      row << CsvImporter::REQUIRED_COLUMNS + %w[dc:title]
      row << [item.id, nil, nil, nil, files.join("||"), nil, nil, nil, nil, nil, "Title"]
    end
    files = files.map{ |f| file_fixture(f).to_s }
    file  = Tempfile.new(%w[test, .csv])
    File.write(file, csv)

    @instance.import(pathname:           file.path,
                     file_paths:         files,
                     submitter:          users(:southwest_admin),
                     primary_collection: collections(:southwest_unit1_empty))

    item.reload
    b = item.bitstreams.where(filename: "gull.jpg").first
    assert b.primary?
    b = item.bitstreams.where(filename: "pooh.jpg").first
    assert !b.primary?
  ensure
    file.unlink
  end

  test "import() sets bundle positions on attached bitstreams" do
    item  = items(:southwest_unit1_collection1_item1)
    item.bitstreams.destroy_all
    files = %w[gull.jpg pooh.jpg]
    csv   = CSV.generate do |row|
      row << CsvImporter::REQUIRED_COLUMNS + %w[dc:title]
      row << [item.id, nil, nil, nil, files.join("||"), nil, nil, nil, nil, nil, "Title"]
    end
    files = files.map{ |f| file_fixture(f).to_s }
    file  = Tempfile.new(%w[test, .csv])
    File.write(file, csv)

    @instance.import(pathname:           file.path,
                     file_paths:         files,
                     submitter:          users(:southwest_admin),
                     primary_collection: collections(:southwest_unit1_empty))

    item.reload
    item.bitstreams.order(:bundle_position).each_with_index do |bs, index|
      assert_equal index, bs.bundle_position
    end
  ensure
    file.unlink
  end

  test "import() ignores files that are already attached to an item" do
    item = items(:southwest_unit1_collection1_item1)
    csv  = CSV.generate do |row|
      row << CsvImporter::REQUIRED_COLUMNS + %w[dc:title]
      row << [item.id, nil, nil, nil, "approved.png", nil, nil, nil, nil, nil, "Title"]
    end
    file = Tempfile.new(%w[test, .csv])
    File.write(file, csv)

    assert_no_difference "Bitstream.count" do
      @instance.import(pathname:           file.path,
                       file_paths:         ["this shouldn't be used"],
                       submitter:          users(:southwest_admin),
                       primary_collection: collections(:southwest_unit1_empty))
    end
  ensure
    file.unlink
  end

  test "import() attaches correct Embargoes to items" do
    package_path = File.join(file_fixture_path, "packages", "csv", "valid_items")
    csv_path     = File.join(package_path, "package.csv")

    @instance.import(pathname:           csv_path,
                     file_paths:         [],
                     submitter:          users(:southwest_admin),
                     primary_collection: collections(:southwest_unit1_empty))
    item = Item.order(created_at: :desc).limit(1).first

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
      row << ["+", nil, nil, nil, nil, nil, nil, nil, nil, nil, "New Item"]
    end
    file = Tempfile.new(%w[test, .csv])
    File.write(file, csv)

    imported_items = []
    @instance.import(pathname:           file.path,
                     file_paths:         [],
                     submitter:          users(:southwest_sysadmin),
                     primary_collection: collections(:southeast_empty),
                     imported_items:     imported_items)
    assert_equal 1, imported_items.length
  ensure
    file.unlink
  end

  test "import() raises an error when an unrecognized element is present in the
  CSV" do
    csv = CSV.generate do |row|
      row << CsvImporter::REQUIRED_COLUMNS + %w[bogus:bogus]
      row << ["+", nil, nil, nil, nil, nil, nil, nil, nil, nil, "New Value"]
    end
    file = Tempfile.new(%w[test, .csv])
    File.write(file, csv)

    assert_raises ArgumentError do
      @instance.import(pathname:           file.path,
                       submitter:          users(:southwest_sysadmin),
                       primary_collection: collections(:southeast_empty))
    end
  ensure
    file.unlink
  end

  test "import() raises an error when a non-existent item ID is present in the
  CSV" do
    csv = CSV.generate do |row|
      row << CsvImporter::REQUIRED_COLUMNS + %w[dc:title]
      row << ["999999", nil, nil, nil, nil, nil, nil, nil, nil, "New Value"]
    end
    file = Tempfile.new(%w[test, .csv])
    File.write(file, csv)

    assert_raises ActiveRecord::RecordNotFound do
      @instance.import(pathname:           file.path,
                       file_paths:         [],
                       submitter:          users(:southwest_sysadmin),
                       primary_collection: collections(:southeast_empty))
    end
  ensure
    file.unlink
  end

  test "import() raises an error for a blank item ID cell" do
    csv = CSV.generate do |row|
      row << CsvImporter::REQUIRED_COLUMNS + %w[dc:title]
      row << [nil, nil, nil, nil, nil, nil, nil, nil, nil, "New Value"]
    end
    file = Tempfile.new(%w[test, .csv])
    File.write(file, csv)

    assert_raises do
      @instance.import(pathname:           file.path,
                       submitter:          users(:southwest_sysadmin),
                       primary_collection: collections(:southeast_empty))
    end
  ensure
    file.unlink
  end

  test "import() updates an existing item" do
    item = items(:southeast_item1)
    csv  = CSV.generate do |row|
      row << CsvImporter::REQUIRED_COLUMNS + %w[dc:title]
      row << [item.id, nil, nil, nil, nil, nil, nil, nil, nil, nil, "New Title"]
    end
    file = Tempfile.new(%w[test, .csv])
    File.write(file, csv)

    @instance.import(pathname:           file.path,
                     file_paths:         [],
                     submitter:          users(:southwest_sysadmin),
                     primary_collection: collections(:southeast_empty))
    item.reload
    assert_equal "New Title", item.title
  ensure
    file.unlink
  end

  test "import() deletes elements corresponding to blank element values" do
    item = items(:southeast_described)
    csv  = CSV.generate do |row|
      row << CsvImporter::REQUIRED_COLUMNS + %w[dc:title dc:subject]
      row << [item.id, nil, nil, nil, nil, nil, nil, nil, nil, nil, "Title", ""]
    end
    file = Tempfile.new(%w[test, .csv])
    File.write(file, csv)

    @instance.import(pathname:           file.path,
                     file_paths:         [],
                     submitter:          users(:southwest_sysadmin),
                     primary_collection: collections(:southeast_empty))
    item.reload
    assert_nil item.element("dc:subject")
  ensure
    file.unlink
  end

  test "import() does not modify elements other than those contained in the
  CSV" do
    item = items(:southeast_described)
    csv  = CSV.generate do |row|
      row << CsvImporter::REQUIRED_COLUMNS + %w[dc:title]
      row << [item.id, nil, nil, nil, nil, nil, nil, nil, nil, nil, "New Title"]
    end
    file = Tempfile.new(%w[test, .csv])
    File.write(file, csv)

    @instance.import(pathname:           file.path,
                     file_paths:         [],
                     submitter:          users(:southwest_sysadmin),
                     primary_collection: collections(:southeast_empty))
    item.reload
    assert_equal "New Title", item.element("dc:title").string      # new value
    assert_equal "Some subject", item.element("dc:subject").string # existing value
  ensure
    file.unlink
  end

  test "import() succeeds the import's task upon success" do
    item = items(:southeast_described)
    task = tasks(:pending)
    csv  = CSV.generate do |row|
      row << CsvImporter::REQUIRED_COLUMNS + %w[dc:title]
      row << [item.id, nil, nil, nil, nil, nil, nil, nil, nil, nil, "New Title"]
    end
    file = Tempfile.new(%w[test, .csv])
    File.write(file, csv)

    @instance.import(pathname:           file.path,
                     file_paths:         [],
                     submitter:          users(:southwest_sysadmin),
                     primary_collection: collections(:southeast_empty),
                     task:               task)
    assert_equal Task::Status::SUCCEEDED, task.status
    assert_equal 1, task.percent_complete
  ensure
    file.unlink
  end

  test "import() fails the import's task upon error" do
    item = items(:southeast_described)
    task = tasks(:pending)
    csv = CSV.generate do |row|
      row << CsvImporter::REQUIRED_COLUMNS + %w[bogus:bogus]
      row << [item.id, nil, nil, nil, nil, nil, nil, nil, nil, "Bogus element value"]
    end
    file = Tempfile.new(%w[test, .csv])
    File.write(file, csv)

    assert_raises do
      @instance.import(pathname:           file.path,
                       submitter:          users(:southwest_sysadmin),
                       primary_collection: collections(:southeast_empty),
                       task:               task)
    end
    assert_equal Task::Status::FAILED, task.status
    assert_equal 0, task.percent_complete
  ensure
    file.unlink
  end

end
