require 'test_helper'

class ItemTest < ActiveSupport::TestCase

  setup do
    setup_elasticsearch
    @instance = items(:item1)
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

  # primary_collection=()

  test "primary_collection=() updates the primary collection" do
    collection2 = collections(:collection2)
    assert_not_equal collection2, @instance.primary_collection
    assert_equal 1, @instance.collections.count

    @instance.primary_collection = collection2
    @instance.reload
    assert_equal collection2, @instance.primary_collection
    assert_equal 2, @instance.collections.count
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
    assert_equal @instance.primary_collection.id,
                 doc[Item::IndexFields::PRIMARY_COLLECTION]
    assert_equal @instance.primary_collection.primary_unit.id,
                 doc[Item::IndexFields::PRIMARY_UNIT]
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

end
