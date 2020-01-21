require 'test_helper'

class UnitTest < ActiveSupport::TestCase

  setup do
    setup_elasticsearch
    @instance = units(:unit1)
  end

  # delete_document()

  test 'delete_document() deletes a document' do
    units = Unit.all.limit(5)
    units.each(&:reindex)
    refresh_elasticsearch
    count = UnitFinder.new.count
    assert count > 0

    Unit.delete_document(units.first.id)
    refresh_elasticsearch
    assert_equal count - 1, UnitFinder.new.count
  end

  # reindex_all()

  test 'reindex_all() reindexes all units' do
    setup_elasticsearch
    assert_equal 0, UnitFinder.new.include_children(true).count

    Unit.reindex_all
    refresh_elasticsearch

    actual = UnitFinder.new.include_children(true).count
    assert actual > 0
    assert_equal Unit.count, actual
  end

  # as_indexed_json()

  test 'as_indexed_json returns the correct structure' do
    doc = @instance.as_indexed_json
    assert_equal 'Unit', doc[Unit::IndexFields::CLASS]
    assert_not_empty doc[Unit::IndexFields::CREATED]
    assert_not_empty doc[Unit::IndexFields::LAST_INDEXED]
    assert_equal @instance.updated_at.utc.iso8601,
                 doc[Unit::IndexFields::LAST_MODIFIED]
    assert_nil doc[Unit::IndexFields::PARENT]
    assert_equal @instance.title, doc[Unit::IndexFields::TITLE]
  end

  # reindex()

  test 'reindex reindexes the instance' do
    assert_equal 0, UnitFinder.new.
        filter(Unit::IndexFields::ID, @instance.id).count

    @instance.reindex
    refresh_elasticsearch

    assert_equal 1, UnitFinder.new.
        filter(Unit::IndexFields::ID, @instance.id).count
  end

end
