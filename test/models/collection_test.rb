require 'test_helper'

class CollectionTest < ActiveSupport::TestCase

  setup do
    setup_opensearch
    @instance = collections(:uiuc_collection1)
    assert @instance.valid?
  end

  # delete_document() (Indexed concern)

  test "delete_document() deletes a document" do
    institution = institutions(:uiuc)
    collections = Collection.
      joins("LEFT JOIN unit_collection_memberships ucm ON ucm.collection_id = collections.id").
      joins("LEFT JOIN units u ON u.id = ucm.unit_id").
      where("u.institution_id": institution.id)
    collections.each(&:reindex)
    refresh_opensearch
    count = Collection.search.institution(institution).count
    assert count > 0

    Collection.delete_document(collections.first.index_id)
    refresh_opensearch
    assert_equal count - 1, Collection.search.institution(institution).count
  end

  # search() (Indexed concern)

  test "search() returns a CollectionRelation" do
    assert_kind_of CollectionRelation, Collection.search
  end

  # all_child_ids()

  test "all_child_ids() returns the correct IDs" do
    collection = collections(:uiuc_collection1)
    child      = collection.all_children.first

    ids        = collection.all_child_ids
    assert_equal 2, ids.count
    assert ids.include?(child.id)
  end

  # all_children()

  test "all_children() returns the correct collections" do
    collection = collections(:uiuc_collection1)
    children   = collection.all_children
    assert_equal 2, children.count
    assert children.first.kind_of?(Collection)
    assert_equal collection, children.first.parent
  end

  # all_managing_groups()

  test "all_managing_groups() returns the correct groups" do
    groups = collections(:uiuc_collection1_collection1_collection1).all_managing_groups
    assert_equal 0, groups.length
  end

  # all_parents()

  test "all_parents() returns the parents" do
    result = collections(:uiuc_collection1_collection1_collection1).all_parents
    assert_equal 2, result.count
    assert_equal collections(:uiuc_collection1_collection1), result[0]
    assert_equal collections(:uiuc_collection1), result[1]
  end

  # all_submitting_groups()

  test "all_submitting_groups() returns the correct groups" do
    groups = collections(:uiuc_collection1_collection1_collection1).all_submitting_groups
    assert_equal 0, groups.length
  end

  # all_unit_administrators()

  test "all_unit_administrators()" do
    assert_equal 2, @instance.all_unit_administrators.length
  end

  test "all_units() returns the correct units" do
    assert_equal 2, @instance.all_units.length
  end

  # reindex_all() (Indexed concern)

  test "reindex_all() reindexes all collections" do
    setup_opensearch
    institution = institutions(:uiuc)
    assert_equal 0, Collection.search.institution(institution).count

    Collection.reindex_all
    refresh_opensearch

    actual = Collection.search.institution(institution).count
    assert actual > 0
    expected = Collection.
      distinct.
      joins("LEFT JOIN unit_collection_memberships ucm ON ucm.collection_id = collections.id").
      joins("LEFT JOIN units u on ucm.unit_id = u.id").
      where("u.institution_id": institution.id).
      where.not(buried: true).
      count
    assert_equal expected, actual
  end

  # as_indexed_json()

  test "as_indexed_json() returns the correct structure" do
    doc = @instance.as_indexed_json
    assert !doc[Collection::IndexFields::BURIED]
    assert_equal "Collection", doc[Collection::IndexFields::CLASS]
    assert_not_empty doc[Collection::IndexFields::CREATED]
    assert_equal @instance.description,
                 doc[Collection::IndexFields::DESCRIPTION]
    assert_equal @instance.handle.handle,
                 doc[Collection::IndexFields::HANDLE]
    assert_equal @instance.institution.key,
                 doc[Collection::IndexFields::INSTITUTION_KEY]
    assert_equal @instance.institution.name,
                 doc[Collection::IndexFields::INSTITUTION_NAME]
    assert_equal @instance.introduction,
                 doc[Collection::IndexFields::INTRODUCTION]
    assert_not_empty doc[Collection::IndexFields::LAST_INDEXED]
    assert_equal @instance.updated_at.utc.iso8601,
                 doc[Collection::IndexFields::LAST_MODIFIED]
    assert_nil doc[Collection::IndexFields::PARENT]
    assert_equal @instance.primary_unit.id,
               doc[Collection::IndexFields::PRIMARY_UNIT]
    assert_equal @instance.provenance,
                 doc[Collection::IndexFields::PROVENANCE]
    assert_equal @instance.rights,
                 doc[Collection::IndexFields::RIGHTS]
    assert_equal @instance.short_description,
                 doc[Collection::IndexFields::SHORT_DESCRIPTION]
    assert_equal @instance.title, doc[Collection::IndexFields::TITLE]
    assert doc[Collection::IndexFields::UNIT_DEFAULT]
    assert_equal %w(Unit1 Unit2),
                 doc[Collection::IndexFields::UNIT_TITLES]
    assert_equal @instance.units.count,
        doc[Collection::IndexFields::UNITS].length
  end

  # buried

  test "buried cannot be set to true when the collection contains any
  non-buried subcollections" do
    assert @instance.valid?
    assert @instance.collections.count > 0
    @instance.items.delete_all
    @instance.buried = true
    assert !@instance.valid?
  end

  test "buried cannot be set to true when the collection contains any
  non-buried items" do
    assert @instance.valid?
    assert @instance.items.count > 0
    @instance.collections.delete_all
    @instance.buried = true
    assert !@instance.valid?
  end

  test "buried can be set to true when there are only buried subcollections
  and items" do
    assert @instance.valid?
    @instance.collections.update_all(buried: true)
    @instance.items.update_all(stage: Item::Stages::BURIED)
    @instance.buried = true
    assert @instance.valid?
  end

  test "buried can be set to true when the collection is empty" do
    assert @instance.valid?
    @instance.collections.delete_all
    @instance.items.delete_all
    @instance.buried = true
    assert @instance.valid?
  end

  # bury!()

  test "bury!() raises an error when the collection contains any non-buried
  subcollections" do
    assert @instance.collections.count > 0
    @instance.items.delete_all
    assert_raises ActiveRecord::RecordInvalid do
      @instance.bury!
    end
  end

  test "bury!() raises an error when the collection contains any non-buried
  items" do
    assert @instance.items.count > 0
    @instance.collections.delete_all
    assert_raises ActiveRecord::RecordInvalid do
      @instance.bury!
    end
  end

  test "bury!() works when the collection contains only buried subcollections
  and items" do
    assert @instance.items.count > 0
    @instance.collections.update_all(buried: true)
    @instance.items.update_all(stage: Item::Stages::BURIED)
    @instance.bury!
    assert @instance.buried
  end

  test "bury!() buries an empty collection" do
    @instance.collections.delete_all
    @instance.items.delete_all
    @instance.bury!
    assert @instance.buried
  end

  # destroy()

  test "destroy() raises an error when there are dependent collections" do
    @instance = collections(:uiuc_collection1_collection1)
    @instance.items.destroy_all
    @instance.all_children.each do |child|
      child.items.destroy_all
    end
    assert @instance.collections.count > 0
    assert_raises ActiveRecord::DeleteRestrictionError do
      @instance.destroy!
    end
  end

  test "destroy() raises an error when there are dependent items" do
    setup_s3
    Import.destroy_all
    @instance.collections.delete_all
    assert @instance.items.count > 0
    assert_raises ActiveRecord::RecordNotDestroyed do
      @instance.destroy!
    end
  end

  test "destroy() succeeds when there are no dependent collections" do
    assert collections(:uiuc_empty).destroy
  end

  # download_count_by_month()

  test "download_count_by_month() raises an error if start_time > end_time" do
    assert_raises ArgumentError do
      @instance.download_count_by_month(start_time: Time.now,
                                        end_time:   Time.now - 1.day)
    end
  end

  test "download_count_by_month() returns a correct count" do
    expected = 0
    @instance.all_children.each do |child_collection|
      child_collection.items.each do |item|
        item.bitstreams.each do |bitstream|
          bitstream.add_download
          expected += 1
        end
      end
    end
    actual = @instance.download_count_by_month
    assert_equal 1, actual.length
    assert_kind_of Time, actual[0]['month']
    assert_equal expected, actual[0]['dl_count']
  end

  test "download_count_by_month() returns a correct count when supplying start
  and end times" do
    Event.destroy_all
    expected = 0
    @instance.all_children.each do |child_collection|
      child_collection.items.each do |item|
        item.bitstreams.each do |bitstream|
          bitstream.add_download
          expected += 1
        end
      end
    end

    # Shift all of the events that were just created 3 months into the past.
    Event.update_all(happened_at: 3.months.ago)

    @instance.all_children.each do |child_collection|
      child_collection.items.each do |item|
        item.bitstreams.each do |bitstream|
          bitstream.add_download
        end
      end
    end

    actual = @instance.download_count_by_month(start_time: 4.months.ago,
                                               end_time:   2.months.ago)
    assert_equal 3, actual.length
    assert_kind_of Time, actual[0]['month']
    assert_equal expected, actual[1]['dl_count']
  end

  # effective_managers()

  test "effective_managers() includes sysadmins" do
    @instance.effective_managers.include?(users(:example_sysadmin))
  end

  test "effective_managers() includes unit admins" do
    @instance.effective_managers.include?(@instance.primary_unit.administering_users.first)
  end

  test "effective_managers() includes managers of parent collections" do
    parent    = collections(:uiuc_collection1)
    @instance = collections(:uiuc_collection1_collection1)
    @instance.effective_managers.include?(parent.managing_users.first)
  end

  test "effective_managers() includes direct managers" do
    @instance.effective_managers.include?(@instance.managing_users.first)
  end

  # effective_metadata_profile()

  test "effective_metadata_profile() returns the assigned metadata profile" do
    profile = metadata_profiles(:uiuc_unused)
    @instance.metadata_profile = profile
    assert_equal profile, @instance.effective_metadata_profile
  end

  test "effective_metadata_profile() falls back to the primary unit's profile
  if no profile is assigned" do
    profile = metadata_profiles(:uiuc_default)
    @instance.metadata_profile = nil
    @instance.primary_unit.metadata_profile = profile
    assert_equal profile, @instance.effective_metadata_profile
  end

  test "effective_metadata_profile() falls back to the institution's default
  profile if no profile is assigned to the primary unit" do
    @instance.metadata_profile = nil
    @instance.primary_unit.metadata_profile = nil
    assert_equal metadata_profiles(:uiuc_default),
                 @instance.effective_metadata_profile
  end

  # effective_submission_profile()

  test "effective_submission_profile() returns the assigned submission profile" do
    profile = submission_profiles(:uiuc_unused)
    @instance.submission_profile = profile
    assert_equal profile, @instance.effective_submission_profile
  end

  test "effective_submission_profile() falls back to the institution's default
  profile if no profile is assigned" do
    @instance.submission_profile = nil
    assert_equal submission_profiles(:uiuc_default),
                 @instance.effective_submission_profile
  end

  # effective_submitters()

  test "effective_submitters() includes sysadmins" do
    @instance.effective_submitters.include?(users(:example_sysadmin))
  end

  test "effective_submitters() includes unit admins" do
    @instance.effective_submitters.include?(@instance.primary_unit.administering_users.first)
  end

  test "effective_submitters() includes managers of parent collections" do
    parent    = collections(:uiuc_collection1)
    @instance = collections(:uiuc_collection1_collection1)
    @instance.effective_submitters.include?(parent.managing_users.first)
  end

  test "effective_submitters() includes direct managers" do
    @instance.effective_submitters.include?(@instance.managing_users.first)
  end

  test "effective_submitters() includes submitters into parent collections" do
    parent    = collections(:uiuc_collection1)
    @instance = collections(:uiuc_collection1_collection1)
    @instance.effective_submitters.include?(parent.submitting_users.first)
  end

  test "effective_submitters() includes direct submitters" do
    @instance.effective_submitters.include?(@instance.submitting_users.first)
  end

  # exhume!()

  test "exhume!() exhumes a buried collection" do
    @instance = collections(:uiuc_buried)
    @instance.units.first.exhume!
    @instance.exhume!
    assert !@instance.buried
  end

  test "exhume!() does nothing to a non-buried collection" do
    @instance.exhume!
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
    other = collections(:uiuc_collection2)
    assert_not_equal @instance.primary_unit, other.primary_unit
    @instance.parent_id = other.id
    assert_raises ActiveRecord::RecordInvalid do
      @instance.save!
    end
  end

  # reindex() (Indexed concern)

  test "reindex reindexes the instance" do
    assert_equal 0, Collection.search.
        institution(institutions(:uiuc)).
        filter(Collection::IndexFields::ID, @instance.index_id).count

    @instance.reindex
    refresh_opensearch

    assert_equal 1, Collection.search.
        institution(institutions(:uiuc)).
        filter(Collection::IndexFields::ID, @instance.index_id).count
  end

  # save()

  test "save() creates an associated handle" do
    @instance = collections(:uiuc_described)
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

  # submissions_reviewed

  test "submissions_reviewed is false by default" do
    c = Collection.new
    assert !c.submissions_reviewed
  end

  # submitted_item_count()

  test "submitted_item_count() returns a correct count when not including
  children" do
    Event.destroy_all
    item_count = 0
    @instance.items.each do |item|
      item.update!(stage: Item::Stages::SUBMITTED)
      item.events.build(event_type: Event::Type::CREATE).save!
      item_count += 1
    end
    assert item_count > 0
    assert_equal item_count,
                 @instance.submitted_item_count(include_children: false)
  end

  test "submitted_item_count() returns a correct count when including children" do
    Event.destroy_all
    item_count = 0
    all_children = @instance.all_children
    assert all_children.length > 1
    all_children.each do |child_collection|
      child_collection.items.each do |item|
        item.update!(stage: Item::Stages::SUBMITTED)
        item.events.build(event_type: Event::Type::CREATE).save!
        item_count += 1
      end
    end
    @instance.items.each do |item|
      item.update!(stage: Item::Stages::SUBMITTED)
      item.events.build(event_type: Event::Type::CREATE).save!
      item_count += 1
    end
    assert item_count > 0
    assert_equal item_count,
                 @instance.submitted_item_count(include_children: true)
  end

  test "submitted_item_count() returns a correct count when supplying start
  and end times" do
    Event.destroy_all
    @instance.items.each do |item|
      item.update!(stage: Item::Stages::SUBMITTED)
      item.events.build(event_type: Event::Type::CREATE).save!
    end
    # Adjust the happened_at property of one of the just-created events to fit
    # inside the time window.
    Event.where(event_type: Event::Type::CREATE).all.first.
      update!(happened_at: 90.minutes.ago)

    assert_equal 1, @instance.submitted_item_count(start_time: 2.hours.ago,
                                                   end_time:   1.hour.ago)
  end

  # submitted_item_count_by_month()

  test "submitted_item_count_by_month() returns a correct count" do
    Event.destroy_all
    expected = 0
    @instance.items.each do |item|
      item.events.build(event_type: Event::Type::CREATE).save!
      expected += 1
    end
    actual = @instance.submitted_item_count_by_month
    assert_equal 1, actual.length
    assert_kind_of Time, actual[0]['month']
    assert_equal expected, actual[0]['count']
  end

  test "submitted_item_count_by_month() returns a correct count when supplying
  start and end times" do
    Event.destroy_all

    expected = 0
    @instance.items.each do |item|
      item.events.build(event_type: Event::Type::CREATE).save!
      expected += 1
    end

    # Shift all of the events that were just created 3 months into the past.
    Event.update_all(happened_at: 3.months.ago)

    @instance.items.each do |item|
      item.events.build(event_type: Event::Type::CREATE).save!
    end

    actual = @instance.submitted_item_count_by_month(start_time: 4.months.ago,
                                                     end_time:   2.months.ago)
    assert_equal 3, actual.length
    assert_kind_of Time, actual[0]['month']
    assert_equal 0, actual[0]['count']
  end

  # unit_default?()

  test "unit_default?() returns false for a non-unit-default collection" do
    assert !collections(:uiuc_described).unit_default?
  end

  test "unit_default?() returns true for a unit-default collection" do
    assert collections(:uiuc_collection1).unit_default?
  end

  # units

  test "units can be empty" do
    @instance.units = []
    assert @instance.save
  end

  test "collection cannot be added to multiple instances of the same unit" do
    @instance.units = []
    unit = units(:uiuc_unit1)
    @instance.units << unit
    assert_raises ActiveRecord::RecordNotUnique do
      @instance.units << unit
    end
  end

end
