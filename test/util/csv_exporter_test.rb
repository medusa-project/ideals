require 'test_helper'

class CsvExporterTest < ActiveSupport::TestCase

  setup do
    @instance = CsvExporter.new
  end

  # export()

  test "export() respects the units argument" do
    unit       = units(:unit1)
    all_units  = [unit]
    all_units += unit.all_children
    all_items  = all_units.map(&:items).flatten
    csv        = @instance.export(units: [unit])
    rows       = CSV.parse(csv)
    assert_equal 1 + all_items.length, rows.length
    assert_equal %w(id dc:title dc:description dc:subject), rows[0]
  end

  test "export() includes child collections" do
    collection       = collections(:collection1)
    all_collections  = [collection]
    all_collections += collection.all_children
    all_items        = all_collections.map(&:items).flatten
    csv              = @instance.export(collections: [collection])
    rows             = CSV.parse(csv)
    assert_equal 1 + all_items.length, rows.length
    assert_equal %w(id dc:title dc:description dc:subject), rows[0]
  end

  test "export() respects the elements argument" do
    collection = collections(:collection1)
    csv        = @instance.export(collections: [collection],
                                  elements:    %w(dc:creator dc:description))
    rows       = CSV.parse(csv)
    assert_equal %w(id dc:creator dc:description), rows[0]
  end

  # export_collection()

  test "export_collection() includes child collections in the CSV" do
    collection       = collections(:collection1)
    all_collections  = [collection]
    all_collections += collection.all_children
    all_items        = all_collections.map(&:items).flatten
    csv              = @instance.export_collection(collection)
    rows             = CSV.parse(csv)
    assert_equal 1 + all_items.length, rows.length
    assert_equal %w(id dc:title dc:description dc:subject), rows[0]
  end

  test "export_collection() respects the elements argument" do
    collection = collections(:collection1)
    csv        = @instance.export_collection(collection,
                                             elements: %w(dc:creator dc:description))
    rows       = CSV.parse(csv)
    assert_equal %w(id dc:creator dc:description), rows[0]
  end

  # export_unit()

  test "export_unit() includes child units in the CSV" do
    unit      = units(:unit1)
    all_items = unit.collections.map(&:items).flatten
    csv       = @instance.export_unit(unit)
    rows      = CSV.parse(csv)
    assert_equal 1 + all_items.length, rows.length
    assert_equal %w(id dc:title dc:description dc:subject), rows[0]
  end

  test "export_unit() respects the elements argument" do
    unit = units(:unit1)
    csv  = @instance.export_unit(unit,
                                 elements: %w(dc:creator dc:description))
    rows = CSV.parse(csv)
    assert_equal %w(id dc:creator dc:description), rows[0]
  end

end
