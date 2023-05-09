require 'test_helper'

class UnitTest < ActiveSupport::TestCase

  setup do
    setup_opensearch
    clear_message_queues
    @instance = units(:uiuc_unit1)
  end

  # delete_document() (Indexed concern)

  test "delete_document() deletes a document" do
    institution = institutions(:uiuc)
    units       = Unit.where(institution: institution)
    units.each(&:reindex)
    refresh_opensearch
    count = Unit.search.institution(institution).count
    assert count > 0

    Unit.delete_document(units.first.index_id)
    refresh_opensearch
    assert_equal count - 1, Unit.search.institution(institution).count
  end

  # search() (Indexed concern)

  test "search() returns a UnitRelation" do
    assert_kind_of UnitRelation, Unit.search
  end

  # reindex_all() (Indexed concern)

  test "reindex_all() reindexes all units" do
    setup_opensearch
    institution = institutions(:uiuc)
    assert_equal 0, Unit.search.
      institution(institution).
      include_children(true).
      count

    Unit.reindex_all
    refresh_opensearch

    actual = Unit.search.
      institution(institution).
      include_children(true).
      count
    assert actual > 0
    assert_equal Unit.where(institution: institution).where.not(buried: true).count,
                 actual
  end

  # all_administrators()

  test "all_administrators() returns the correct users" do
    admins = units(:uiuc_unit1_unit2_unit1).all_administrators
    assert_equal 2, admins.length
  end

  # all_administering_groups()

  test "all_administering_groups() returns the correct users" do
    groups = units(:uiuc_unit1_unit2_unit1).all_administering_groups
    assert_equal 1, groups.length
  end

  # all_child_ids()

  test "all_child_ids() returns the correct units" do
    unit  = units(:uiuc_unit1)
    child = unit.all_children.first
    ids   = unit.all_child_ids
    assert_equal 3, ids.count
    assert ids.include?(child.id)
  end

  # all_children()

  test "all_children() returns the correct units" do
    unit     = units(:uiuc_unit1)
    children = unit.all_children
    assert_equal 3, children.count
    assert children.first.kind_of?(Unit)
  end

  # all_parents()

  test "all_parents() returns the parents" do
    result = units(:uiuc_unit1_unit2_unit1).all_parents
    assert_equal 2, result.count
    assert_equal units(:uiuc_unit1_unit2), result[0]
    assert_equal units(:uiuc_unit1), result[1]
  end

  # as_indexed_json()

  test "as_indexed_json() returns the correct structure" do
    doc = @instance.as_indexed_json
    assert_not_empty doc[Unit::IndexFields::ADMINISTRATORS]
    assert !doc[Unit::IndexFields::BURIED]
    assert_equal "Unit", doc[Unit::IndexFields::CLASS]
    assert_not_empty doc[Unit::IndexFields::CREATED]
    assert_nil doc[Unit::IndexFields::HANDLE]
    assert_equal @instance.institution.key, doc[Unit::IndexFields::INSTITUTION_KEY]
    assert_equal @instance.institution.name, doc[Unit::IndexFields::INSTITUTION_NAME]
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
    assert units(:uiuc_unit1_unit2).child?
  end

  # destroy()

  test "destroy() raises an error when there are dependent units" do
    assert_raises ActiveRecord::DeleteRestrictionError do
      units(:uiuc_unit1_unit2).destroy!
    end
  end

  test "destroy() raises an error when there are dependent collections" do
    assert_raises ActiveRecord::DeleteRestrictionError do
      @instance.destroy!
    end
  end

  test "destroy() succeeds when there are no dependent units or collections" do
    assert units(:uiuc_empty).destroy
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
    profile = metadata_profiles(:uiuc_unused)
    @instance.metadata_profile = profile
    assert_equal profile, @instance.effective_metadata_profile
  end

  test "effective_metadata_profile() falls back to the institution's default
  profile if no profile is assigned" do
    @instance.metadata_profile = nil
    assert_equal metadata_profiles(:uiuc_default),
                 @instance.effective_metadata_profile
  end

  # exhume!()

  test "exhume!() exhumes a buried unit" do
    @instance = units(:uiuc_buried)
    @instance.exhume!
    assert !@instance.buried
  end

  test "exhume!() does nothing to a non-buried unit" do
    @instance.exhume!
  end

  # move_to()

  test "move_to() raises an error if an institution is not provided" do
    assert_raises ArgumentError do
      @instance.move_to(institution: nil,
                        user:        users(:uiuc_sysadmin))
    end
  end

  test "move_to() raises an error if a user is not provided" do
    assert_raises ArgumentError do
      @instance.move_to(institution: institutions(:northeast),
                        user:        nil)
    end
  end

  test "move_to() raises an error when attempting to move to the same
  institution" do
    assert_raises ArgumentError do
      @instance.move_to(institution: @instance.institution,
                        user:        users(:uiuc_sysadmin))
    end
  end

  test "move_to() raises an error when the destination institution already has
  a unit with the same name" do
    setup_s3
    institution = institutions(:northeast)
    Unit.create!(institution: institution, title: @instance.title)
    assert_raises do
      @instance.move_to(institution: institution,
                        user:        users(:uiuc_sysadmin))
    end
  end

  test "move_to() moves all child units" do
    setup_s3
    institution = institutions(:northeast)
    @instance.move_to(institution: institution,
                      user:        users(:uiuc_sysadmin))
    ([@instance] + @instance.units).each do |child|
      assert_equal institution, child.institution
    end
  end

  test "move_to() disassociates administrators and administrator groups from
  units" do
    setup_s3
    assert @instance.administrators.count > 0
    assert @instance.administrator_groups.count > 0
    @instance.move_to(institution: institutions(:northeast),
                      user:        users(:uiuc_sysadmin))
    assert_equal 0, @instance.administrators.count
    assert_equal 0, @instance.administrator_groups.count
  end

  test "move_to() moves all collections" do
    setup_s3
    institution = institutions(:northeast)
    @instance.move_to(institution: institution,
                      user:        users(:uiuc_sysadmin))
    ([@instance] + @instance.units).each do |unit|
      unit.collections.each do |collection|
        assert_equal institution, collection.institution
      end
    end
  end

  test "move_to() disassociates administrators and submitters from
  collections" do
    setup_s3
    institution     = institutions(:northeast)
    # First, make sure there are some administrators & submitters to remove.
    admin_count     = 0
    submitter_count = 0
    ([@instance] + @instance.units).each do |unit|
      unit.collections.each do |collection|
        admin_count += collection.administrators.count
        submitter_count += collection.submitters.count
      end
    end
    assert admin_count > 0
    assert submitter_count > 0

    @instance.move_to(institution: institution,
                      user:        users(:uiuc_sysadmin))
    ([@instance] + @instance.units).each do |unit|
      unit.collections.each do |collection|
        assert_equal 0, collection.administrators.count
        assert_equal 0, collection.submitters.count
      end
    end
  end

  test "move_to() adds any necessary RegisteredElements needed by items" do
    setup_s3
    src_institution          = @instance.institution
    dest_institution         = institutions(:northeast)
    src_institution_count_1  = src_institution.registered_elements.count
    dest_institution_count_1 = dest_institution.registered_elements.count
    assert src_institution_count_1 > dest_institution_count_1
    @instance.move_to(institution: dest_institution,
                      user:        users(:uiuc_sysadmin))

    src_institution_count_2  = src_institution.registered_elements.count
    dest_institution_count_2 = dest_institution.registered_elements.count
    assert_equal src_institution_count_1, src_institution_count_2
    assert dest_institution_count_2 > dest_institution_count_1
  end

  test "move_to() moves all items" do
    setup_s3
    institution = institutions(:northeast)
    @instance.move_to(institution: institution,
                      user:        users(:uiuc_sysadmin))
    ([@instance] + @instance.units).each do |unit|
      unit.collections.each do |collection|
        collection.items.each do |item|
          assert_equal institution, item.institution
        end
      end
    end
  end

  test "move_to() reconfigures items' AscribedElements to point to the
  corresponding new RegisteredElements" do
    setup_s3
    institution = institutions(:northeast)
    @instance.move_to(institution: institution,
                      user:        users(:uiuc_sysadmin))
    ([@instance] + @instance.units).each do |unit|
      unit.collections.each do |collection|
        collection.items.each do |item|
          item.elements.each do |asc_e|
            assert_equal asc_e.registered_element.institution, institution
          end
        end
      end
    end
  end

  test "move_to() removes all items' BitstreamAuthorizations" do
    setup_s3
    # Ensure that there are some BitstreamAuthorizations to remove.
    ([@instance] + @instance.units).each do |unit|
      unit.collections.each do |collection|
        collection.items.each do |item|
          item.bitstream_authorizations.build(user_group: user_groups(:sysadmin)).save!
        end
      end
    end

    institution = institutions(:northeast)
    @instance.move_to(institution: institution,
                      user:        users(:uiuc_sysadmin))
    ([@instance] + @instance.units).each do |unit|
      unit.collections.each do |collection|
        collection.items.each do |item|
          assert_equal 0, item.bitstream_authorizations.count
        end
      end
    end
  end

  test "move_to() updates bitstreams' keys" do
    setup_s3
    institution = institutions(:northeast)
    @instance.move_to(institution: institution,
                      user:        users(:uiuc_sysadmin))
    ([@instance] + @instance.units).each do |unit|
      unit.collections.each do |collection|
        collection.items.each do |item|
          item.bitstreams.each do |bitstream|
            assert bitstream.effective_key.start_with?("institutions/#{institution.key}/")
          end
        end
      end
    end
  end

  test "move_to() moves bitstreams' corresponding storage objects" do
    setup_s3
    institution = institutions(:northeast)
    @instance.move_to(institution: institution,
                      user:        users(:uiuc_sysadmin))
    ([@instance] + @instance.units).each do |unit|
      unit.collections.each do |collection|
        collection.items.each do |item|
          item.bitstreams.each do |bitstream|
            assert PersistentStore.instance.object_exists?(key: bitstream.effective_key)
          end
        end
      end
    end
  end

  test "move_to() sends delete and ingest messages to Medusa" do
    setup_s3
    institution  = institutions(:northeast)
    ingest_queue = institution.outgoing_message_queue
    delete_queue = @instance.institution.outgoing_message_queue
    @instance.move_to(institution: institution,
                      user:        users(:uiuc_sysadmin))
    ([@instance] + @instance.units).each do |unit|
      unit.collections.each do |collection|
        collection.items.each do |item|
          item.bitstreams.each do |bitstream|
            if bitstream.permanent_key.present?
              AmqpHelper::Connector[:ideals].with_parsed_message(ingest_queue) do |message|
                assert_not_nil message
              end
            end
            if bitstream.medusa_uuid_was.present?
              AmqpHelper::Connector[:ideals].with_parsed_message(delete_queue) do |message|
                assert_equal "delete", message['operation']
                assert_not_nil message['uuid']
              end
            end
          end
        end
      end
    end
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
    user = users(:example)
    assert_not_equal user, @instance.primary_administrator
    assert_equal 1, @instance.administrators.count

    @instance.primary_administrator = user
    @instance.reload

    assert_equal user, @instance.primary_administrator
    assert_equal 2, @instance.administrators.count
  end

  test "primary_administrator=() sets the primary administrator to a user who
  is already an administrator" do
    user = users(:example)
    @instance.administering_users << user
    @instance.save!

    @instance.primary_administrator = user
    @instance.reload

    assert_equal user, @instance.primary_administrator
    assert_equal 2, @instance.administrators.count
  end

  test "primary_administrator cannot be set on child units" do
    unit = units(:uiuc_unit1_unit2)
    assert unit.valid?
    unit.primary_administrator = users(:example_sysadmin)
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
    refresh_opensearch

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
    assert_equal @instance, units(:uiuc_unit1_unit2).root_parent
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
        item.update!(stage: Item::Stages::SUBMITTED)
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
        item.update!(stage: Item::Stages::SUBMITTED)
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
        item.update!(stage: Item::Stages::SUBMITTED)
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

  # title

  test "title must be present" do
    @instance.title = nil
    assert !@instance.valid?
    @instance.title = ""
    assert !@instance.valid?
  end

end
