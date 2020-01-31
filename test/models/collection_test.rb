require 'test_helper'

class CollectionTest < ActiveSupport::TestCase

  setup do
    setup_elasticsearch
    @instance = collections(:collection1)
  end

  # delete_document() (Indexed concern)

  test "delete_document() deletes a document" do
    collections = Collection.all.limit(5)
    collections.each(&:reindex)
    refresh_elasticsearch
    count = Collection.search.count
    assert count > 0

    Collection.delete_document(collections.first.index_id)
    refresh_elasticsearch
    assert_equal count - 1, Collection.search.count
  end

  # search() (Indexed concern)

  test "search() returns a CollectionFinder" do
    assert_kind_of CollectionFinder, Collection.search
  end

  # primary_unit=()

  test "primary_unit=() updates the primary unit" do
    unit2 = units(:unit2)
    assert_not_equal unit2, @instance.primary_unit
    assert_equal 1, @instance.units.count

    @instance.primary_unit = unit2
    @instance.reload
    assert_equal unit2, @instance.primary_unit
    assert_equal 2, @instance.units.count
  end

  # reindex_all() (Indexed concern)

  test "reindex_all() reindexes all items" do
    setup_elasticsearch
    assert_equal 0, Collection.search.count

    Collection.reindex_all
    refresh_elasticsearch

    actual = Collection.search.count
    assert actual > 0
    assert_equal Collection.count, actual
  end

  # as_indexed_json()

  test "as_indexed_json() returns the correct structure" do
    doc = @instance.as_indexed_json
    assert_equal "Collection", doc[Collection::IndexFields::CLASS]
    assert_not_empty doc[Collection::IndexFields::CREATED]
    assert_equal @instance.description,
                 doc[Collection::IndexFields::DESCRIPTION]
    assert_not_empty doc[Collection::IndexFields::LAST_INDEXED]
    assert_equal @instance.updated_at.utc.iso8601,
                 doc[Collection::IndexFields::LAST_MODIFIED]
    assert_equal @instance.primary_unit.id,
               doc[Collection::IndexFields::PRIMARY_UNIT]
    assert_equal @instance.title,
                 doc[Collection::IndexFields::TITLE]
    assert_equal @instance.units.count,
        doc[Collection::IndexFields::UNITS].length
  end

  # reindex() (Indexed concern)

  test "reindex reindexes the instance" do
    assert_equal 0, Collection.search.
        filter(Collection::IndexFields::ID, @instance.index_id).count

    @instance.reindex
    refresh_elasticsearch

    assert_equal 1, Collection.search.
        filter(Collection::IndexFields::ID, @instance.index_id).count
  end

end
