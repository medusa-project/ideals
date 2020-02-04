require 'test_helper'

class UnitTest < ActiveSupport::TestCase

  setup do
    setup_elasticsearch
    @instance = units(:unit1)
  end

  # delete_document() (Indexed concern)

  test 'delete_document() deletes a document' do
    units = Unit.all.limit(5)
    units.each(&:reindex)
    refresh_elasticsearch
    count = Unit.search.count
    assert count > 0

    Unit.delete_document(units.first.index_id)
    refresh_elasticsearch
    assert_equal count - 1, Unit.search.count
  end

  # search() (Indexed concern)

  test "search() returns a UnitFinder" do
    assert_kind_of UnitFinder, Unit.search
  end

  # reindex_all() (Indexed concern)

  test "reindex_all() reindexes all units" do
    setup_elasticsearch
    assert_equal 0, Unit.search.include_children(true).count

    Unit.reindex_all
    refresh_elasticsearch

    actual = Unit.search.include_children(true).count
    assert actual > 0
    assert_equal Unit.count, actual
  end

  # all_children()

  test "all_children() returns the correct units" do
    assert_equal 3, units(:unit1).all_children.count
  end

  # all_parents()

  test "all_parents() returns the parents" do
    result = units(:unit1_unit2_unit1).all_parents
    assert_equal 2, result.count
    assert_equal units(:unit1_unit2), result[0]
    assert_equal units(:unit1), result[1]
  end

  # as_indexed_json()

  test "as_indexed_json returns the correct structure" do
    doc = @instance.as_indexed_json
    assert_equal 'Unit', doc[Unit::IndexFields::CLASS]
    assert_not_empty doc[Unit::IndexFields::CREATED]
    assert_not_empty doc[Unit::IndexFields::LAST_INDEXED]
    assert_equal @instance.updated_at.utc.iso8601,
                 doc[Unit::IndexFields::LAST_MODIFIED]
    assert_nil doc[Unit::IndexFields::PARENT]
    assert_equal @instance.title, doc[Unit::IndexFields::TITLE]
  end

  # parent_id

  test "parent_id cannot be set to the instance ID" do
    @instance.parent_id = @instance.id
    assert_raises ActiveRecord::RecordInvalid do
      @instance.save!
    end
  end

  test "parent_id cannot be set to a child ID" do
    @instance.parent_id = @instance.units.first.id
    assert_raises ActiveRecord::RecordInvalid do
      @instance.save!
    end
  end

  # reindex() (Indexed concern)

  test "reindex reindexes the instance" do
    assert_equal 0, Unit.search.
        filter(Unit::IndexFields::ID, @instance.index_id).count

    @instance.reindex
    refresh_elasticsearch

    assert_equal 1, Unit.search.
        filter(Unit::IndexFields::ID, @instance.index_id).count
  end

  # title

  test "title must be present" do
    @instance.title = nil
    assert !@instance.valid?
    @instance.title = ""
    assert !@instance.valid?
  end

end
