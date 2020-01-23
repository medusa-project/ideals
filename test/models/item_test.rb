require 'test_helper'

class ItemTest < ActiveSupport::TestCase

  setup do
    setup_elasticsearch
    @instance = items(:item1)
  end

  # delete_document()

  test 'delete_document() deletes a document' do
    items = Item.all.limit(5)
    items.each(&:reindex)
    refresh_elasticsearch
    count = ItemFinder.new.count
    assert count > 0

    Item.delete_document(items.first.id)
    refresh_elasticsearch
    assert_equal count - 1, ItemFinder.new.count
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

  # reindex_all()

  test 'reindex_all() reindexes all items' do
    setup_elasticsearch
    assert_equal 0, ItemFinder.new.count

    Item.reindex_all
    refresh_elasticsearch

    actual = ItemFinder.new.count
    assert actual > 0
    assert_equal Item.count, actual
  end

  # as_indexed_json()

  test 'as_indexed_json() returns the correct structure' do
    doc = @instance.as_indexed_json
    assert_equal "Item", doc[Item::IndexFields::CLASS]
    assert_empty doc[Item::IndexFields::COLLECTIONS]
    assert_not_empty doc[Item::IndexFields::CREATED]
    assert_not_empty doc[Item::IndexFields::LAST_INDEXED]
    assert_equal @instance.updated_at.utc.iso8601,
                 doc[Item::IndexFields::LAST_MODIFIED]
    assert_nil doc[Item::IndexFields::PRIMARY_COLLECTION]
  end

  # reindex()

  test 'reindex reindexes the instance' do
    assert_equal 0, ItemFinder.new.
        filter(Item::IndexFields::ID, @instance.id).count

    @instance.reindex
    refresh_elasticsearch

    assert_equal 1, ItemFinder.new.
        filter(Item::IndexFields::ID, @instance.id).count
  end

end
