require 'test_helper'

class UnitTest < ActiveSupport::TestCase

  setup do
    setup_elasticsearch
    @instance = units(:unit1)
  end

  # create()

  test "create() creates a default collection" do
    unit = Unit.create!(title: "New Unit",
                        institution: institutions(:somewhere))
    assert_equal 1, unit.collections.length
    m = unit.unit_collection_memberships.first
    assert m.unit_default
    assert_equal "Default collection for #{unit.title}", m.collection.title
  end

  # delete_document() (Indexed concern)

  test "delete_document() deletes a document" do
    units = Unit.all.limit(5)
    units.each(&:reindex)
    refresh_elasticsearch
    count = Unit.search.institution(institutions(:uiuc)).count
    assert count > 0

    Unit.delete_document(units.first.index_id)
    refresh_elasticsearch
    assert_equal count - 1, Unit.search.institution(institutions(:uiuc)).count
  end

  # search() (Indexed concern)

  test "search() returns a UnitRelation" do
    assert_kind_of UnitRelation, Unit.search
  end

  # reindex_all() (Indexed concern)

  test "reindex_all() reindexes all units" do
    setup_elasticsearch
    assert_equal 0, Unit.search.
      institution(institutions(:uiuc)).
      include_children(true).
      count

    Unit.reindex_all
    refresh_elasticsearch

    actual = Unit.search.
      institution(institutions(:uiuc)).
      include_children(true).
      count
    assert actual > 0
    assert_equal Unit.where.not(buried: true).count, actual
  end

  # all_administrators()

  test "all_administrators() returns the correct users" do
    admins = units(:unit1_unit2_unit1).all_administrators
    assert_equal 2, admins.length
  end

  # all_administrator_groups()

  test "all_administrator_groups() returns the correct users" do
    groups = units(:unit1_unit2_unit1).all_administrator_groups
    assert_equal 0, groups.length
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

  test "as_indexed_json() returns the correct structure" do
    doc = @instance.as_indexed_json
    assert_equal 13, doc.length
    assert_not_empty doc[Unit::IndexFields::ADMINISTRATORS]
    assert !doc[Unit::IndexFields::BURIED]
    assert_equal "Unit", doc[Unit::IndexFields::CLASS]
    assert_not_empty doc[Unit::IndexFields::CREATED]
    assert_equal @instance.institution.key, doc[Unit::IndexFields::INSTITUTION_KEY]
    assert_equal @instance.introduction, doc[Unit::IndexFields::INTRODUCTION]
    assert_not_empty doc[Unit::IndexFields::LAST_INDEXED]
    assert_equal @instance.updated_at.utc.iso8601,
                 doc[Unit::IndexFields::LAST_MODIFIED]
    assert_nil doc[Unit::IndexFields::PARENT]
    assert_equal @instance.primary_administrator.id,
                 doc[Unit::IndexFields::PRIMARY_ADMINISTRATOR]
    assert_equal @instance.rights, doc[Unit::IndexFields::RIGHTS]
    assert_equal @instance.short_description, doc[Unit::IndexFields::SHORT_DESCRIPTION]
    assert_equal @instance.title, doc[Unit::IndexFields::TITLE]
  end

  # buried

  test "buried cannot be set to true when the unit contains any non-buried
  subunits" do
    @instance.valid?
    @instance.collections.delete_all
    assert @instance.units.count > 0
    @instance.buried = true
    assert !@instance.valid?
  end

  test "buried cannot be set to true when the unit contains any non-buried
  collections" do
    @instance.valid?
    assert @instance.collections.count > 0
    @instance.buried = true
    assert !@instance.valid?
  end

  test "buried can be set to true when there are only buried subunits and
  collections" do
    @instance.valid?
    @instance.units.update_all(buried: true)
    @instance.collections.update_all(buried: true)
    @instance.buried = true
    assert @instance.valid?
  end

  test "buried can be set to true when the unit is empty" do
    @instance.valid?
    @instance.units.delete_all
    @instance.collections.delete_all
    @instance.buried = true
    assert @instance.valid?
  end

  # bury!()

  test "bury!() raises an error when the unit contains any non-buried subunits" do
    assert @instance.units.count > 0
    @instance.collections.delete_all
    assert_raises ActiveRecord::RecordInvalid do
      @instance.bury!
    end
  end

  test "bury!() raises an error when the unit contains any non-buried
  collections" do
    assert @instance.collections.count > 0
    assert_raises ActiveRecord::RecordInvalid do
      @instance.bury!
    end
  end

  test "bury!() works when there are only buried subunits and collections" do
    @instance.units.update_all(buried: true)
    @instance.collections.update_all(buried: true)
    @instance.bury!
    assert @instance.buried
  end

  test "bury!() buries an empty unit" do
    @instance.units.delete_all
    @instance.collections.delete_all
    @instance.bury!
    assert @instance.buried
  end

  # child?()

  test "child?() returns false for root units" do
    assert !@instance.child?
  end

  test "child?() returns true for child units" do
    assert units(:unit1_unit2).child?
  end

  # create_default_collection()

  test "create_default_collection() creates a correct default collection" do
    @instance.collections.destroy_all
    col = @instance.create_default_collection
    assert col.unit_collection_memberships.first.unit_default
    assert_equal "Default collection for #{@instance.title}", col.title
    assert_equal "This collection was created automatically along with its parent unit.",
                 col.description
  end

  # default_collection()

  test "default_collection() returns the default collection" do
    assert_equal collections(:collection1), @instance.default_collection
  end

  test "default_collection() returns nil when there is no  default collection" do
    @instance = units(:empty)
    assert_nil @instance.default_collection
  end

  # destroy()

  test "destroy() raises an error when there are dependent units" do
    assert_raises ActiveRecord::DeleteRestrictionError do
      units(:unit1_unit2).destroy!
    end
  end

  test "destroy() raises an error when there are dependent collections" do
    assert_raises ActiveRecord::DeleteRestrictionError do
      @instance.destroy!
    end
  end

  test "destroy() succeeds when there are no dependent units or collections" do
    assert units(:empty).destroy
  end

  # download_count_by_month()

  test "download_count_by_month() raises an error if start_time > end_time" do
    assert_raises ArgumentError do
      @instance.download_count_by_month(start_time: Time.now,
                                        end_time:   Time.now - 1.day)
    end
  end

  test "download_count_by_month() returns a correct count" do
    Event.destroy_all
    expected = 0
    @instance.collections.each do |collection|
      collection.items.each do |item|
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
    expected = 0
    @instance.collections.each do |collection|
      collection.items.each do |item|
        item.bitstreams.each do |bitstream|
          bitstream.add_download
          expected += 1
        end
      end
    end

    # Shift all of the events that were just created 3 months into the past.
    Event.update_all(happened_at: 3.months.ago)

    @instance.collections.each do |collection|
      collection.items.each do |item|
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

  # effective_metadata_profile()

  test "effective_metadata_profile() returns the assigned metadata profile" do
    profile = metadata_profiles(:unused)
    @instance.metadata_profile = profile
    assert_equal profile, @instance.effective_metadata_profile
  end

  test "effective_metadata_profile() falls back to the default profile if no
  profile is assigned" do
    @instance.metadata_profile = nil
    assert_equal metadata_profiles(:default),
                 @instance.effective_metadata_profile
  end

  # exhume!()

  test "exhume!() exhumes a buried unit" do
    @instance = units(:buried)
    @instance.exhume!
    assert !@instance.buried
  end

  test "exhume!() does nothing to a non-buried unit" do
    @instance.exhume!
  end

  # item_download_counts()

  test "item_download_counts() returns correct results with no arguments" do
    Event.destroy_all
    item_count = 0
    @instance.collections.each do |collection|
      collection.items.each do |item|
        item.bitstreams.each do |bitstream|
          bitstream.add_download
        end
        # The query won't return items without a title.
        item.elements.build(registered_element: registered_elements(:dc_title),
                            string: "This is the title").save!
        item_count += 1 if item.bitstreams.any?
      end
    end
    result = @instance.item_download_counts
    assert_equal 10, result.length
    assert_equal 3, result[0]['dl_count']
  end

  test "item_download_counts() returns correct results when supplying limit
  and offset" do
    Event.destroy_all
    @instance.collections.each do |collection|
      collection.items.each do |item|
        item.bitstreams.each do |bitstream|
          bitstream.add_download
        end
        # The query won't return items without a title.
        item.elements.build(registered_element: registered_elements(:dc_title),
                            string:             "This is the title").save!
      end
    end
    result = @instance.item_download_counts(offset: 1, limit: 2)
    assert_equal 2, result.length
    assert_equal 3, result[0]['dl_count']
  end

  test "item_download_counts() returns correct results when supplying start
  and end times" do
    Event.destroy_all
    @instance.collections.each do |collection|
      collection.items.each do |item|
        item.bitstreams.each do |bitstream|
          bitstream.add_download
        end
        # The query won't return items without a title.
        item.elements.build(registered_element: registered_elements(:dc_title),
                            string: "This is the title").save!
      end
    end

    # Adjust the happened_at property of one of the just-created bitstream
    # download events to fit inside the time window.
    Event.where(event_type: Event::Type::DOWNLOAD).all.first.
      update!(happened_at: 90.minutes.ago)

    result = @instance.item_download_counts(start_time: 2.hours.ago,
                                            end_time:   1.hour.ago)
    assert_equal 1, result.length
    assert_equal 1, result[0]['dl_count']
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

  # primary_administrator

  test "primary_administrator=() sets the primary administrator to a user who
  is not already an administrator" do
    user = users(:norights)
    assert_not_equal user, @instance.primary_administrator
    assert_equal 1, @instance.administrators.count

    @instance.primary_administrator = user
    @instance.reload

    assert_equal user, @instance.primary_administrator
    assert_equal 2, @instance.administrators.count
  end

  test "primary_administrator=() sets the primary administrator to a user who
  is already an administrator" do
    user = users(:norights)
    @instance.administering_users << user
    @instance.save!

    @instance.primary_administrator = user
    @instance.reload

    assert_equal user, @instance.primary_administrator
    assert_equal 2, @instance.administrators.count
  end

  test "primary_administrator cannot be set on child units" do
    unit = units(:unit1_unit2)
    assert unit.valid?
    unit.primary_administrator = users(:local_sysadmin)
    unit.reload
    assert !unit.valid?
  end

  # reindex() (Indexed concern)

  test "reindex reindexes the instance" do
    assert_equal 0, Unit.search.
        institution(institutions(:uiuc)).
        filter(Unit::IndexFields::ID, @instance.index_id).
        count

    @instance.reindex
    refresh_elasticsearch

    assert_equal 1, Unit.search.
        institution(institutions(:uiuc)).
        filter(Unit::IndexFields::ID, @instance.index_id).
        count
  end

  # root_parent()

  test "root_parent() returns the instance for root units" do
    assert_same @instance, @instance.root_parent
  end

  test "root_parent() returns the root parent for child units" do
    assert_equal @instance, units(:unit1_unit2).root_parent
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

  # submitted_item_count()

  test "submitted_item_count() returns a correct count when not including children" do
    Event.destroy_all
    item_count = 0
    @instance.collections.each do |collection|
      collection.items.each do |item|
        item.events.build(event_type: Event::Type::CREATE).save!
        item_count += 1
      end
    end
    assert item_count > 0
    assert_equal item_count,
                 @instance.submitted_item_count(include_children: false)
  end

  test "submitted_item_count() returns a correct count when including children" do
    Event.destroy_all
    item_count = 0
    @instance.collections.each do |collection|
      collection.items.each do |item|
        item.events.build(event_type: Event::Type::CREATE).save!
        item_count += 1
      end
    end
    assert_equal item_count,
                 @instance.submitted_item_count(include_children: true)
  end

  test "submitted_item_count() returns a correct count when supplying start and
  end times" do
    Event.destroy_all
    @instance.collections.each do |collection|
      collection.items.each do |item|
        item.events.build(event_type: Event::Type::CREATE).save!
      end
    end

    Event.where(event_type: Event::Type::CREATE).
      limit(1).
      update_all(happened_at: 90.minutes.ago)

    assert_equal 1, @instance.submitted_item_count(start_time: 2.hours.ago,
                                                   end_time:   1.hour.ago)
  end

  # submitted_item_count_by_month()

  test "submitted_item_count_by_month() returns a correct count" do
    Event.destroy_all
    expected = 0
    @instance.collections.each do |collection|
      collection.items.each do |item|
        item.events.build(event_type: Event::Type::CREATE).save!
        expected += 1
      end
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
    @instance.collections.each do |collection|
      collection.items.each do |item|
        item.events.build(event_type: Event::Type::CREATE).save!
        expected += 1
      end
    end

    # Shift all of the events that were just created 3 months into the past.
    Event.update_all(happened_at: 3.months.ago)

    @instance.collections.each do |collection|
      collection.items.each do |item|
        item.events.build(event_type: Event::Type::CREATE).save!
      end
    end

    actual = @instance.submitted_item_count_by_month(start_time: 4.months.ago,
                                                     end_time:   2.months.ago)
    assert_equal 3, actual.length
    assert_kind_of Time, actual[0]['month']
    assert_equal expected, actual[1]['count']
  end

  # submitting_item_count()

  test "submitting_item_count() returns a correct count when not including
  children" do
    assert_equal 1, @instance.submitting_item_count(include_children: false)
  end

  test "submitting_item_count() returns a correct count when including children" do
    assert_equal 1, @instance.submitting_item_count(include_children: true)
  end

  # title

  test "title must be present" do
    @instance.title = nil
    assert !@instance.valid?
    @instance.title = ""
    assert !@instance.valid?
  end

end
