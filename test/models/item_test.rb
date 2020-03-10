require 'test_helper'

class ItemTest < ActiveSupport::TestCase

  setup do
    setup_elasticsearch
    @instance = items(:item1)
  end

  # base-level tests

  test "destroying an instance destroys its dependent AscribedElements" do
    item = items(:described)
    elements = item.elements
    assert elements.count > 0
    item.destroy!
    elements.each do |element|
      assert element.destroyed?
    end
  end

  # delete_document() (Indexed concern)

  test "delete_document() deletes a document" do
    items = Item.all.limit(5)
    items.each(&:reindex)
    refresh_elasticsearch
    count = Item.search.count
    assert count > 0

    Item.delete_document(items.first.index_id)
    refresh_elasticsearch
    assert_equal count - 1, Item.search.count
  end

  # reindex_all() (Indexed concern)

  test "reindex_all() reindexes all items" do
    setup_elasticsearch
    assert_equal 0, Item.search.count

    Item.reindex_all
    refresh_elasticsearch

    expected = Item.count
    actual = Item.search.count
    assert actual > 0
    assert_equal expected, actual
  end

  # search() (Indexed concern)

  test "search() returns an ItemRelation" do
    assert_kind_of ItemRelation, Item.search
  end

  # all_collection_managers()

  test "all_collection_managers() returns the expected users" do
    assert_equal 1, @instance.all_collection_managers.length
  end

  # all_collection_submitters()

  test "all_collection_submitters() returns the expected users" do
    assert_equal 1, @instance.all_collection_submitters.length
  end

  # all_collections()

  test "all_collections() returns the expected collections" do
    assert_equal 1, @instance.all_collections.length
  end

  # all_unit_administrators()

  test "all_unit_administrators() returns the expected users" do
    assert_equal 1, @instance.all_unit_administrators.length
  end

  # all_units()

  test "all_units() returns the expected units" do
    assert_equal 2, @instance.all_units.length
  end

  # as_indexed_json()

  test "as_indexed_json() returns the correct structure" do
    doc = @instance.as_indexed_json
    assert_equal "Item", doc[Item::IndexFields::CLASS]
    assert_not_empty doc[Item::IndexFields::COLLECTION_TITLES]
    assert_not_empty doc[Item::IndexFields::COLLECTIONS]
    assert_not_empty doc[Item::IndexFields::CREATED]
    assert doc[Item::IndexFields::DISCOVERABLE]
    assert doc[Item::IndexFields::SUBMITTING]
    assert_not_empty doc[Item::IndexFields::LAST_INDEXED]
    assert_equal @instance.updated_at.utc.iso8601,
                 doc[Item::IndexFields::LAST_MODIFIED]
    assert_equal @instance.primary_collection_id,
                 doc[Item::IndexFields::PRIMARY_COLLECTION]
    assert_equal @instance.primary_collection.primary_unit.id,
                 doc[Item::IndexFields::PRIMARY_UNIT]
    assert_equal @instance.submitter.id,
                 doc[Item::IndexFields::SUBMITTER]
    assert_not_empty doc[Item::IndexFields::UNIT_TITLES]
    assert_not_empty doc[Item::IndexFields::UNITS]
    assert !doc[Item::IndexFields::WITHDRAWN]

    item = items(:described)
    doc = item.as_indexed_json
    assert_equal 3, item.elements.length
    title = item.elements.find{ |e| e.name == Configuration.instance.elements[:title] }
    assert_equal [title.string],
                 doc[title.registered_element.indexed_name]
  end

  # description() (Describable concern)

  test "description() returns the description element value" do
    item = items(:described)
    assert_equal "Some description", item.description
  end

  test "description() returns an empty string when there is no description element" do
    item = items(:undescribed)
    assert_equal "", item.description
  end

  # effective_metadata_profile()

  test "effective_metadata_profile() returns the metadata profile assigned to
  the primary collection" do
    assert_equal @instance.primary_collection.metadata_profile,
                 @instance.effective_metadata_profile
  end

  test "effective_metadata_profile() falls back to the default profile if there
  is no primary collection assigned" do
    @instance.primary_collection_id = nil
    assert_equal metadata_profiles(:default),
                 @instance.effective_metadata_profile
  end

  # element() (Describable concern)

  test "element() returns a matching element" do
    assert_equal "Some title", items(:described).element("dc:title").string
    assert_equal "Some title", items(:described).element(:"dc:title").string
  end

  test "element() returns nil if no such element exists" do
    assert_nil @instance.element("bogus")
  end

  # metadata_profile()

  test "metadata_profile() returns the primary collection's effective metadata profile" do
    assert_equal metadata_profiles(:default), @instance.metadata_profile
  end

  # primary_unit()

  test "primary_unit() returns the primary unit" do
    assert_same @instance.primary_collection.primary_unit,
                @instance.primary_unit
  end

  # reindex() (Indexed concern)

  test "reindex reindexes the instance" do
    assert_equal 0, Item.search.filter(Item::IndexFields::ID, @instance.index_id).count

    @instance.reindex
    refresh_elasticsearch

    assert_equal 1, Item.search.filter(Item::IndexFields::ID, @instance.index_id).count
  end

  # title() (Describable concern)

  test "title() returns the title element value" do
    item = items(:described)
    assert_equal "Some title", item.title
  end

  test "title() returns an empty string when there is no title element" do
    item = items(:undescribed)
    assert_equal "", item.title
  end

end
