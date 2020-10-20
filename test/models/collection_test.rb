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

  test "search() returns a CollectionRelation" do
    assert_kind_of CollectionRelation, Collection.search
  end

  # all_children()

  test "all_children() returns the correct collections" do
    assert_equal 2, collections(:collection1).all_children.count
  end

  # all_parents()

  test "all_parents() returns the parents" do
    result = collections(:collection1_collection1_collection1).all_parents
    assert_equal 2, result.count
    assert_equal collections(:collection1_collection1), result[0]
    assert_equal collections(:collection1), result[1]
  end

  # all_unit_administrators()

  test "all_unit_administrators()" do
    assert_equal 1, @instance.all_unit_administrators.length
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
    assert_nil doc[Collection::IndexFields::PARENT]
    assert_equal @instance.primary_unit_id,
               doc[Collection::IndexFields::PRIMARY_UNIT]
    assert_equal [@instance.submitting_users.first.id],
                 doc[Collection::IndexFields::SUBMITTERS]
    assert doc[Collection::IndexFields::UNIT_DEFAULT]
    assert_equal %w(Unit1 Unit2),
                 doc[Collection::IndexFields::UNIT_TITLES]
    assert_equal @instance.units.count,
        doc[Collection::IndexFields::UNITS].length

    collection = collections(:described)
    doc = collection.as_indexed_json
    assert_equal 3, collection.elements.length
    title = collection.elements.find{ |e| e.name == Configuration.instance.elements[:title] }
    assert_equal [title.string],
                 doc[title.registered_element.indexed_name]
  end

  # description() (Describable concern)

  test "description() returns the description element value" do
    collection = collections(:described)
    assert_equal "Some description", collection.description
  end

  test "description() returns an empty string when there is no description element" do
    collection = collections(:undescribed)
    assert_equal "", collection.description
  end

  # destroy()

  test "destroy() raises an error when there are dependent collections" do
    assert_raises ActiveRecord::DeleteRestrictionError do
      collections(:collection1_collection1).destroy!
    end
  end

  test "destroy() succeeds when there are no dependent collections" do
    assert collections(:empty).destroy
  end

  # effective_managers()

  test "effective_managers() includes sysadmins" do
    @instance.effective_managers.include?(users(:admin))
  end

  test "effective_managers() includes unit admins" do
    @instance.effective_managers.include?(@instance.primary_unit.administering_users.first)
  end

  test "effective_managers() includes managers of parent collections" do
    parent    = collections(:collection1)
    @instance = collections(:collection1_collection1)
    @instance.effective_managers.include?(parent.managing_users.first)
  end

  test "effective_managers() includes direct managers" do
    @instance.effective_managers.include?(@instance.managing_users.first)
  end

  # effective_metadata_profile()

  test "effective_metadata_profile() returns the assigned metadata profile" do
    profile = metadata_profiles(:unused)
    @instance.metadata_profile = profile
    assert_equal profile, @instance.effective_metadata_profile
  end

  test "effective_metadata_profile() falls back to the default profile if no profile is assigned" do
    @instance.metadata_profile = nil
    assert_equal metadata_profiles(:default),
                 @instance.effective_metadata_profile
  end

  # effective_primary_unit()

  test "effective_primary_unit() returns the primary unit if set" do
    assert_equal @instance.primary_unit, @instance.effective_primary_unit
  end

  test "effective_primary_unit() returns another unit if the primary unit is not set" do
    @instance.primary_unit = nil
    assert @instance.effective_primary_unit.kind_of?(Unit)
  end

  # effective_submission_profile()

  test "effective_submission_profile() returns the assigned submission profile" do
    profile = submission_profiles(:unused)
    @instance.submission_profile = profile
    assert_equal profile, @instance.effective_submission_profile
  end

  test "effective_submission_profile() falls back to the default profile if no
  profile is assigned" do
    @instance.submission_profile = nil
    assert_equal submission_profiles(:default),
                 @instance.effective_submission_profile
  end

  # effective_submitters()

  test "effective_submitters() includes sysadmins" do
    @instance.effective_submitters.include?(users(:admin))
  end

  test "effective_submitters() includes unit admins" do
    @instance.effective_submitters.include?(@instance.primary_unit.administering_users.first)
  end

  test "effective_submitters() includes managers of parent collections" do
    parent    = collections(:collection1)
    @instance = collections(:collection1_collection1)
    @instance.effective_submitters.include?(parent.managing_users.first)
  end

  test "effective_submitters() includes direct managers" do
    @instance.effective_submitters.include?(@instance.managing_users.first)
  end

  test "effective_submitters() includes submitters into parent collections" do
    parent    = collections(:collection1)
    @instance = collections(:collection1_collection1)
    @instance.effective_submitters.include?(parent.submitting_users.first)
  end

  test "effective_submitters() includes direct submitters" do
    @instance.effective_submitters.include?(@instance.submitting_users.first)
  end

  # element() (Describable concern)

  test "element() returns a matching element" do
    assert_equal "Some title", collections(:described).element("dc:title").string
    assert_equal "Some title", collections(:described).element(:"dc:title").string
  end

  test "element() returns nil if no such element exists" do
    assert_nil @instance.element("bogus")
  end

  # parent_id

  test "parent_id cannot be set to the instance ID" do
    @instance.parent_id = @instance.id
    assert_raises ActiveRecord::RecordInvalid do
      @instance.save!
    end
  end

  test "parent_id cannot be set to a child ID" do
    @instance.parent_id = @instance.collections.first.id
    assert_raises ActiveRecord::RecordInvalid do
      @instance.save!
    end
  end

  test "parent_id cannot be set to an ID of a collection in a different unit" do
    other = collections(:empty)
    assert_not_equal @instance.primary_unit, other.primary_unit
    @instance.parent_id = other.id
    assert_raises ActiveRecord::RecordInvalid do
      @instance.save!
    end
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

  # save()

  test "save() creates an associated handle" do
    assert_nil @instance.handle
    @instance.save!
    assert_not_nil @instance.handle
  end

  test "save() does not replace an associated handle" do
    @instance.save!
    handle = @instance.handle
    @instance.updated_at = Time.now # dirty the instance
    @instance.save!
    @instance.reload
    assert_equal handle.id, @instance.handle.id
  end

  # title() (Describable concern)

  test "title() returns the title element value" do
    collection = collections(:described)
    assert_equal "Some title", collection.title
  end

  test "title() returns an empty string when there is no title element" do
    collection = collections(:undescribed)
    assert_equal "", collection.title
  end

  # unit_default

  test "setting a profile as the unit default sets all other instances to
  not-unit-default" do
    unit = units(:unit1)
    assert_equal 1, Collection.where(primary_unit: unit, unit_default: true).count
    Collection.create!(primary_unit: unit, unit_default: true)
    assert_equal 1, Collection.where(primary_unit: unit, unit_default: true).count
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
