require 'test_helper'

class CollectionTest < ActiveSupport::TestCase

  setup do
    setup_elasticsearch
    @instance = collections(:collection1)
    assert @instance.valid?
  end

  # base-level tests

  test "destroying an instance destroys its dependent AscribedElements" do
    collection = collections(:described)
    elements = collection.elements
    assert elements.count > 0
    collection.destroy!
    elements.each do |element|
      assert element.destroyed?
    end
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

  # all_units()

  test "all_units() returns the expected units" do
    assert_equal 2, @instance.all_units.length
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
    assert_not_empty doc[Collection::IndexFields::LAST_INDEXED]
    assert_equal @instance.updated_at.utc.iso8601,
                 doc[Collection::IndexFields::LAST_MODIFIED]
    assert_equal [@instance.managing_users.first.id],
                 doc[Collection::IndexFields::MANAGERS]
    assert_equal @instance.primary_unit_id,
               doc[Collection::IndexFields::PRIMARY_UNIT]
    assert_equal [@instance.submitting_users.first.id],
                 doc[Collection::IndexFields::SUBMITTERS]
    assert_equal @instance.units.count,
        doc[Collection::IndexFields::UNITS].length

    collection = collections(:described)
    doc = collection.as_indexed_json
    assert_equal 2, collection.elements.length
    title = collection.elements.find{ |e| e.name == Configuration.instance.title_element }
    assert_equal [title.string],
                 doc[title.registered_element.indexed_name]
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

  # title()

  test "title() returns the title element value" do
    collection = collections(:described)
    assert_equal "Some title", collection.title
  end

  test "title() returns an empty string when there is no title element" do
    collection = collections(:undescribed)
    assert_equal "", collection.title
  end

  # units

  test "units can be empty" do
    @instance.units = []
    assert @instance.save
  end

  test "collection cannot be added to multiple instances of the same unit" do
    @instance.units = []
    unit = units(:unit1)
    @instance.units << unit
    assert_raises ActiveRecord::RecordNotUnique do
      @instance.units << unit
    end
  end

end
