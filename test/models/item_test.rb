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

    actual = Item.search.count
    assert actual > 0
    assert_equal Item.count, actual
  end

  # search() (Indexed concern)

  test "search() returns an ItemFinder" do
    assert_kind_of ItemFinder, Item.search
  end

  # as_indexed_json()

  test "as_indexed_json() returns the correct structure" do
    doc = @instance.as_indexed_json
    assert_equal "Item", doc[Item::IndexFields::CLASS]
    assert_not_empty doc[Item::IndexFields::COLLECTIONS]
    assert_not_empty doc[Item::IndexFields::CREATED]
    assert_not_empty doc[Item::IndexFields::LAST_INDEXED]
    assert_equal @instance.updated_at.utc.iso8601,
                 doc[Item::IndexFields::LAST_MODIFIED]
    assert_equal @instance.primary_collection_id,
                 doc[Item::IndexFields::PRIMARY_COLLECTION]
    assert_equal @instance.primary_collection.primary_unit.id,
                 doc[Item::IndexFields::PRIMARY_UNIT]
    # TODO: metadata
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

  # title()

  test "title() returns the title element value" do
    item = items(:described)
    assert_equal "Some title", item.title
  end

end
