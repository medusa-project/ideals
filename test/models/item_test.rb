require 'test_helper'

class ItemTest < ActiveSupport::TestCase

  include ActionMailer::TestHelper

  setup do
    setup_elasticsearch
    setup_s3
    @instance = items(:item1)
  end

  teardown do
    AmqpHelper::Connector[:ideals].clear_queues(Message.outgoing_queue)
  end

  # Stages

  test "Stages.all() returns values in order" do
    assert_equal Item::Stages::all.sort, Item::Stages::all
  end

  # delete_document() (Indexed concern)

  test "delete_document() deletes a document" do
    items = Item.all.limit(5)
    items.each(&:reindex)
    refresh_elasticsearch
    count = Item.search.institution(institutions(:uiuc)).count
    assert count > 0

    Item.delete_document(items.first.index_id)
    refresh_elasticsearch
    assert_equal count - 1, Item.search.institution(institutions(:uiuc)).count
  end

  # non_embargoed()

  test "non_embargoed() returns all non-all-access-embargoed items" do
    assert_equal Item.count - 1, Item.non_embargoed.count
  end

  # reindex_all() (Indexed concern)

  test "reindex_all() reindexes all items" do
    setup_elasticsearch
    assert_equal 0, Item.search.institution(institutions(:uiuc)).count

    Item.reindex_all
    refresh_elasticsearch

    expected = Item.where.not(stage: Item::Stages::BURIED).count
    actual   = Item.search.institution(institutions(:uiuc)).count
    assert actual > 0
    assert_equal expected, actual
  end

  # search() (Indexed concern)

  test "search() returns an ItemRelation" do
    assert_kind_of ItemRelation, Item.search.institution(institutions(:uiuc))
  end

  # all_access_embargoes()

  test "all_access_embargoes() returns all all-access embargoes" do
    assert_equal 0, @instance.all_access_embargoes.length

    @instance = items(:embargoed)
    assert_equal 1, @instance.all_access_embargoes.length
  end

  # all_collection_managers()

  test "all_collection_managers() returns the expected users" do
    assert_equal 1, @instance.all_collection_managers.length
  end

  # all_collection_submitters()

  test "all_collection_submitters() returns the expected users" do
    assert_equal 1, @instance.all_collection_submitters.length
  end

  # all_collections()

  test "all_collections() returns the expected collections" do
    assert_equal 1, @instance.all_collections.length
  end

  # all_unit_administrators()

  test "all_unit_administrators() returns the expected users" do
    assert_equal 2, @instance.all_unit_administrators.length
  end

  # all_units()

  test "all_units() returns the expected units" do
    assert_equal 2, @instance.all_units.length
  end

  # approve()

  test "approve() sets the stage to approved" do
    item = items(:described)
    item.approve
    assert_equal Item::Stages::APPROVED, item.stage
  end

  test "approve() creates an associated dcterms:available element if one does
  not already exist" do
    item = items(:submitting)
    item.approve
    assert_not_nil item.element("dcterms:available").string
  end

  test "approve() does not create an associated dcterms:available element if
  one already exists" do
    item = items(:described)
    item.stage = Item::Stages::APPROVED
    item.elements.build(registered_element: RegisteredElement.find_by_name("dcterms:available"),
                        string:             "whatever")
    item.approve
    assert_equal 1, item.elements.select{ |e| e.name == "dcterms:available" }.length
  end

  # approved?()

  test "approved?() returns true when the stage is set to APPROVED" do
    @instance.stage = Item::Stages::APPROVED
    assert @instance.approved?
  end

  test "approved?() returns false when the stage is not set to APPROVED" do
    @instance.stage = Item::Stages::SUBMITTING
    assert !@instance.approved?
  end

  # as_change_hash()

  test "as_change_hash() returns the correct structure" do
    @instance = items(:described)
    # add another title to test handling of multiple same-named elements
    @instance.elements.build(registered_element: registered_elements(:dc_title),
                             string: "Alternate title")
    # add an embargo
    @instance.embargoes.build(kind:       Embargo::Kind::ALL_ACCESS,
                              expires_at: Time.now + 1.day)
    hash = @instance.as_change_hash
    # we will assume that if one property is correct, the rest are
    assert_equal Item::Stages::label_for(Item::Stages::APPROVED), hash['stage']

    # test associated elements
    assert_equal "Some title", hash['element:dc:title:string']
    assert_equal "Alternate title", hash['element:dc:title-2:string']

    # test embargoes
    assert_equal "ALL_ACCESS", hash['embargo:0:kind']

    # test bitstreams
    @instance = items(:item1)
    hash = @instance.as_change_hash
    assert_equal "escher_lego.jpg",
                 hash['bitstream:escher_lego.jpg:original_filename']
  end

  # as_indexed_json()

  test "as_indexed_json() returns the correct structure" do
    doc = @instance.as_indexed_json
    assert_equal "Item", doc[Item::IndexFields::CLASS]
    assert_not_empty doc[Item::IndexFields::COLLECTION_TITLES]
    assert_not_empty doc[Item::IndexFields::COLLECTIONS]
    assert_not_empty doc[Item::IndexFields::CREATED]
    assert_equal 0, doc[Item::IndexFields::EMBARGOES].length
    assert_equal 3, doc[Item::IndexFields::FILENAMES].length
    assert_empty doc[Item::IndexFields::FULL_TEXT]
    assert_match /\w+ \w* \w+/,
                 doc[Item::IndexFields::GROUP_BY_UNIT_AND_COLLECTION_SORT_KEY]
    assert_equal @instance.handle.handle, doc[Item::IndexFields::HANDLE]
    assert_equal @instance.institution.key,
                 doc[Item::IndexFields::INSTITUTION_KEY]
    assert_not_empty doc[Item::IndexFields::LAST_INDEXED]
    assert_equal @instance.updated_at.utc.iso8601,
                 doc[Item::IndexFields::LAST_MODIFIED]
    assert_equal @instance.primary_collection.id,
                 doc[Item::IndexFields::PRIMARY_COLLECTION]
    assert_equal @instance.primary_collection.primary_unit.id,
                 doc[Item::IndexFields::PRIMARY_UNIT]
    assert_equal Item::Stages::APPROVED, doc[Item::IndexFields::STAGE]
    assert_equal @instance.submitter.id,
                 doc[Item::IndexFields::SUBMITTER]
    assert_not_empty doc[Item::IndexFields::UNIT_TITLES]
    assert_not_empty doc[Item::IndexFields::UNITS]

    item = items(:described)
    doc = item.as_indexed_json
    assert_equal 3, item.elements.length
    title = item.elements.find{ |e| e.name == Configuration.instance.elements[:title] }
    assert_equal [title.string],
                 doc[title.registered_element.indexed_field]
  end

  # assign_handle()

  test "assign_handle() does nothing if the instance already has a handle" do
    assert_not_nil @instance.handle
    @instance.assign_handle
  end

  test "assign_handle() assigns a handle" do
    item = items(:described)
    item.assign_handle
    assert_not_nil item.handle.suffix
  end

  test "assign_handle() puts the created handle to the server" do
    item = items(:described)
    item.assign_handle
    assert item.handle.exists_on_server?
  end

  test "assign_handle() creates an identifier element" do
    item = items(:described)
    item.assign_handle
    assert_equal item.handle.handle_net_url, item.element("dcterms:identifier").uri
  end

  # buried?()

  test "buried?() returns true when the stage is set to BURIED" do
    @instance.stage = Item::Stages::BURIED
    assert @instance.buried?
  end

  test "buried?() returns false when the stage is not set to BURIED" do
    assert !@instance.buried?
  end

  # bury!()

  test "bury!() sets the stage to BURIED" do
    @instance.bury!
    assert_equal Item::Stages::BURIED, @instance.stage
  end

  test "bury!() creates an associated Event" do
    @instance.bury!
    assert_equal 1, @instance.events.where(event_type: Event::Type::DELETE).count
  end

  test "bury!() does nothing to a buried item" do
    @instance = items(:buried)
    @instance.bury!
  end

  # complete_submission()

  test "complete_submission() creates an associated dc:date:submitted element" do
    item = items(:described)
    item.complete_submission
    assert_not_nil item.element("dc:date:submitted").string
  end

  test "complete_submission() sets the stage to submitted if the collection is
  reviewing submissions" do
    item = items(:described)
    item.primary_collection.submissions_reviewed = true
    item.complete_submission
    assert_equal Item::Stages::SUBMITTED, item.stage
  end

  test "complete_submission() sets the stage to approved if the collection is
  not reviewing submissions" do
    item = items(:described)
    item.primary_collection.submissions_reviewed = false
    item.complete_submission
    assert_equal Item::Stages::APPROVED, item.stage
  end

  test "complete_submission() does not create an associated dcterms:available
  element if the collection is reviewing submissions" do
    item = items(:submitting)
    item.primary_collection.submissions_reviewed = true
    item.complete_submission
    assert_nil item.element("dcterms:available")
  end

  test "complete_submission() creates an associated dcterms:available element
  if the collection is not reviewing submissions" do
    item = items(:submitting)
    item.primary_collection.submissions_reviewed = false
    item.complete_submission
    assert_not_nil item.element("dcterms:available").string
  end

  test "complete_submission() does not assign a handle if the collection is
  reviewing submissions" do
    item = items(:described)
    item.primary_collection.submissions_reviewed = true
    item.complete_submission
    assert_nil item.handle
  end

  test "complete_submission() assigns a handle if the collection is not
  reviewing submissions" do
    item = items(:described)
    item.primary_collection.submissions_reviewed = false
    item.complete_submission
    assert_not_nil item.handle.suffix
    assert_equal item.handle.handle_net_url, item.element("dcterms:identifier").uri
  end

  test "complete_submission() does not move any associated Bitstreams into
  permanent storage if the collection is reviewing submissions" do
    item    = items(:described)
    item.primary_collection.submissions_reviewed = true
    fixture = file_fixture("escher_lego.jpg")
    @instance.bitstreams.each do |bs|
      File.open(fixture, "r") do |file|
        bs.upload_to_staging(file)
      end
    end

    item.complete_submission

    assert_equal item.bitstreams.count,
                 item.bitstreams.where(permanent_key: nil).count
  end

  test "complete_submission() moves all associated Bitstreams into
  permanent storage if the collection is not reviewing submissions" do
    item    = items(:described)
    fixture = file_fixture("escher_lego.jpg")
    @instance.bitstreams.each do |bs|
      File.open(fixture, "r") do |file|
        bs.upload_to_staging(file)
      end
    end

    item.complete_submission

    assert_equal item.bitstreams.count,
                 item.bitstreams.where.not(permanent_key: nil).count
  end

  # delete_from_permanent_storage()

  test "delete_from_permanent_storage() deletes all associated Bitstreams from
  permanent storage" do
    filename = "escher_lego.jpg"
    fixture  = file_fixture(filename)
    @instance.bitstreams.each do |bs|
      bs.update!(permanent_key: Bitstream.permanent_key(@instance.id, filename))
      bs.upload_to_permanent(fixture)
    end

    @instance.delete_from_permanent_storage

    assert_equal @instance.bitstreams.count,
                 @instance.bitstreams.where(permanent_key: nil).count
  end

  # description() (Describable concern)

  test "description() returns the description element value" do
    item = items(:described)
    assert_equal "Some description", item.description
  end

  test "description() returns an empty string when there is no description
  element" do
    item = items(:undescribed)
    assert_equal "", item.description
  end

  # destroy()

  test "destroy() fails for in-archive items" do
    item = items(:in_medusa)
    assert_raises do
      item.destroy!
    end
  end

  test "destroy() succeeds for not-in-archive items" do
    item = items(:submitting)
    item.destroy!
    assert item.destroyed?
  end

  test "destroy() destroys dependent AscribedElements" do
    item = items(:described)
    elements = item.elements
    assert elements.count > 0
    item.destroy!
    elements.each do |element|
      assert element.destroyed?
    end
  end

  # download_count_by_month()

  test "download_count_by_month() raises an error if start_time > end_time" do
    assert_raises ArgumentError do
      @instance.download_count_by_month(start_time: Time.now,
                                        end_time:   Time.now - 1.day)
    end
  end

  test "download_count_by_month() returns correct counts" do
    Event.destroy_all
    expected = 0
    @instance.bitstreams.each do |bitstream|
      bitstream.add_download
      expected += 1
    end
    actual = @instance.download_count_by_month
    assert_equal 1, actual.length
    assert_kind_of Time, actual[0]['month']
    assert_equal expected, actual[0]['dl_count']
  end

  test "download_count_by_month() returns correct counts when supplying start
  and end times" do
    expected = 0
    @instance.bitstreams.each do |bitstream|
      bitstream.add_download
      expected += 1
    end

    # Shift all of the events that were just created 3 months into the past.
    Event.update_all(happened_at: 3.months.ago)

    @instance.bitstreams.each do |bitstream|
      bitstream.add_download
    end

    actual = @instance.download_count_by_month(start_time: 4.months.ago,
                                               end_time:   2.months.ago)
    assert_equal 3, actual.length
    assert_kind_of Time, actual[0]['month']
    assert_equal expected, actual[1]['dl_count']
  end

  # effective_metadata_profile()

  test "effective_metadata_profile() returns the metadata profile assigned to
  the primary collection" do
    assert_equal @instance.primary_collection.metadata_profile,
                 @instance.effective_metadata_profile
  end

  test "effective_metadata_profile() falls back to the default profile if there
  is no primary collection assigned" do
    @instance.primary_collection = nil
    assert_equal metadata_profiles(:default),
                 @instance.effective_metadata_profile
  end

  # effective_primary_collection()

  test "effective_primary_collection() returns the primary collection when set" do
    assert_equal @instance.primary_collection,
                 @instance.effective_primary_collection
  end

  test "effective_primary_collection() returns another collection if the
  primary collection is not set" do
    @instance.collection_item_memberships.update_all(primary: false)
    assert @instance.effective_primary_collection.kind_of?(Collection)
  end

  # effective_primary_unit()

  test "effective_primary_unit() returns the primary collection's primary unit" do
    assert_equal @instance.primary_collection.primary_unit,
                 @instance.effective_primary_unit
  end

  test "effective_primary_unit() returns another collection's primary unit if
  the primary collection is not set" do
    @instance.collection_item_memberships.update_all(primary: false)
    assert @instance.effective_primary_unit.kind_of?(Unit)
  end

  # effective_submission_profile()

  test "effective_submission_profile() returns the submission profile assigned
  to the primary collection" do
    assert_equal @instance.primary_collection.submission_profile,
                 @instance.effective_submission_profile
  end

  test "effective_submission_profile() falls back to the default profile if
  there is no primary collection assigned" do
    @instance.primary_collection = nil
    assert_equal submission_profiles(:default),
                 @instance.effective_submission_profile
  end

  # element() (Describable concern)

  test "element() returns a matching element" do
    assert_equal "Some title", items(:described).element("dc:title").string
    assert_equal "Some title", items(:described).element(:"dc:title").string
  end

  test "element() returns nil if no such element exists" do
    assert_nil @instance.element("bogus")
  end

  # embargoed_for?()

  test "embargoed_for?() returns false for an item with no embargoes" do
    assert !@instance.embargoed_for?(users(:norights))
  end

  test "embargoed_for?() returns false for an item with only a download embargo" do
    @instance.embargoes.build(kind:       Embargo::Kind::DOWNLOAD,
                              expires_at: Time.now + 1.year).save!
    assert !@instance.embargoed_for?(users(:norights))
  end

  test "embargoed_for?() returns false for an item with an all-access embargo to
  which the given user is exempt" do
    user    = users(:norights)
    group   = user_groups(:temp)
    embargo = @instance.embargoes.build(kind:       Embargo::Kind::ALL_ACCESS,
                                        expires_at: Time.now + 1.year)
    group.users         << user
    embargo.user_groups << group
    embargo.save!
    group.save!

    assert !@instance.embargoed_for?(user)
  end

  test "embargoed_for?() returns true for an item with an all-access embargo to
  which the given user is not exempt" do
    @instance.embargoes.build(kind:       Embargo::Kind::ALL_ACCESS,
                              expires_at: Time.now + 1.year).save!
    assert @instance.embargoed_for?(users(:norights))
  end

  # exhume!()

  test "exhume!() sets the stage to APPROVED" do
    @instance = items(:buried)
    @instance.exhume!
    assert_equal Item::Stages::APPROVED, @instance.stage
  end

  test "exhume!() creates an associated Event" do
    @instance = items(:buried)
    @instance.exhume!
    assert_equal 1, @instance.events.where(event_type: Event::Type::UNDELETE).count
  end

  test "exhume!() does nothing to a non-buried item" do
    @instance.exhume!
  end

  # institution()

  test "institution() returns the primary collection's primary unit's institution" do
    assert_equal @instance.primary_collection.primary_unit.institution,
                 @instance.institution
  end

  # metadata_profile()

  test "metadata_profile() returns the primary collection's effective metadata
  profile" do
    assert_equal metadata_profiles(:default), @instance.metadata_profile
  end

  # move_into_permanent_storage()

  test "move_into_permanent_storage() moves all associated Bitstreams into
  permanent storage" do
    fixture = file_fixture("escher_lego.jpg")
    @instance.bitstreams.each do |bs|
      File.open(fixture, "r") do |file|
        bs.upload_to_staging(file)
      end
    end

    @instance.move_into_permanent_storage

    assert_equal @instance.bitstreams.count,
                 @instance.bitstreams.where.not(permanent_key: nil).count
  end

  # owning_ids()

  test "owning_ids() returns the correct IDs" do
    collection  = @instance.primary_collection
    unit        = collection.primary_unit
    institution = unit.institution
    expected    = {
      "collection_id"  => collection.id,
      "unit_id"        => unit.id,
      "institution_id" => institution.id
    }
    assert_equal expected, @instance.owning_ids
  end

  # primary_unit()

  test "primary_unit() returns the primary unit" do
    assert_same @instance.primary_collection.primary_unit,
                @instance.primary_unit
  end

  # reindex() (Indexed concern)

  test "reindex reindexes the instance" do
    assert_equal 0, Item.search.
      institution(institutions(:uiuc)).
      filter(Item::IndexFields::ID, @instance.index_id).
      count

    @instance.reindex
    refresh_elasticsearch

    assert_equal 1, Item.search.
      institution(institutions(:uiuc)).
      filter(Item::IndexFields::ID, @instance.index_id).
      count
  end

  # representative_bitstream()

  test "representative_bitstream() returns the primary bitstream if one exists" do
    @instance = Item.create
    b1 = @instance.bitstreams.build(primary: true,
                                    bundle: Bitstream::Bundle::CONTENT,
                                    original_filename: "image.jpg")
    b2 = @instance.bitstreams.build(primary: false,
                                    bundle: Bitstream::Bundle::LICENSE,
                                    original_filename: "license.txt")

    assert_same b1, @instance.representative_bitstream
  end

  test "representative_bitstream() returns a bitstream in the content bundle if
  a primary bitstream does not exist" do
    @instance = Item.create
    b1 = @instance.bitstreams.build(primary:           false,
                                    bundle:            Bitstream::Bundle::CONTENT,
                                    original_filename: "image.jpg")
    b2 = @instance.bitstreams.build(primary:           false,
                                    bundle:            Bitstream::Bundle::LICENSE,
                                    original_filename: "license.txt")

    assert_same b1, @instance.representative_bitstream
  end

  test "representative_bitstream() returns nil if no representative bitstream
  exists" do
    @instance = Item.create
    @instance.bitstreams.build(primary:           false,
                               bundle:            Bitstream::Bundle::NOTES,
                               original_filename: "notes.txt")
    @instance.bitstreams.build(primary:           false,
                               bundle:            Bitstream::Bundle::LICENSE,
                               original_filename: "license.txt")

    assert_nil @instance.representative_bitstream
  end

  # required_elements_present?()

  test "required_elements_present?() returns false if not all required elements
  are present" do
    @instance.elements.destroy_all
    assert !@instance.required_elements_present?
  end

  test "required_elements_present?() returns true if all required elements are
  present" do
    @instance.elements.build(registered_element: registered_elements(:dc_title),
                             string:             "Title").save
    assert @instance.required_elements_present?
  end

  # save()

  test "save() prunes duplicate AscribedElements" do
    re = registered_elements(:dc_title)
    @instance.elements.destroy_all
    @instance.elements.build(registered_element: re,
                             string:             "cats",
                             uri:                "http://example.org/cats")
    @instance.elements.build(registered_element: re,
                             string:             "cats",
                             uri:                "http://example.org/cats")
    @instance.elements.build(registered_element: re,
                             string:             "dogs",
                             uri:                "http://example.org/dogs")
    @instance.elements.build(registered_element: re,
                             string:             "dogs",
                             uri:                nil)
    @instance.save!

    @instance.reload
    assert_equal 3, @instance.elements.length
    assert_equal 1, @instance.elements.where(string: "cats",
                                             uri:    "http://example.org/cats").count
    assert_equal 1, @instance.elements.where(string: "dogs",
                                             uri:    "http://example.org/dogs").count
    assert_equal 1, @instance.elements.where(string: "dogs",
                                             uri:    nil).count
  end

  test "save() sends an email when the stage changes from submitting to
  submitted and the primary collection is reviewing submissions" do
    @instance = items(:submitting)
    assert_emails 1 do
      @instance.update!(stage: Item::Stages::SUBMITTED)
    end
  end

  test "save() does not send an email when the stage changes from submitting to
  submitted and the primary collection is not reviewing submissions" do
    @instance = items(:submitting)
    @instance.primary_collection.update!(submissions_reviewed: false)
    assert_emails 0 do
      @instance.update!(stage: Item::Stages::SUBMITTED)
    end
  end

  # set_primary_collection()

  test "set_primary_collection() sets an existing collection as primary" do
    col = @instance.collections.first
    @instance.set_primary_collection(col)
    @instance.reload
    assert_equal col, @instance.primary_collection
  end

  test "set_primary_collection() sets a new collection as primary" do
    col = collections(:collection2)
    assert_not_equal col, @instance.primary_collection
    @instance.set_primary_collection(col)
    @instance.reload
    assert_equal col, @instance.primary_collection
  end

  # stage

  test "stage must be set to an available Stages constant value" do
    assert ActiveRecord::RecordInvalid do
      @instance.update!(stage: 999)
    end
  end

  test "stage cannot be changed from buried when the item's owning collections
  are all buried" do
    @instance = items(:buried)
    @instance.collection_item_memberships.destroy_all
    @instance.collections << collections(:buried)
    assert ActiveRecord::RecordInvalid do
      @instance.update!(stage: Item::Stages::APPROVED)
    end
  end

  # submitted?()

  test "submitted?() returns true when the stage is set to SUBMITTED" do
    @instance.stage = Item::Stages::SUBMITTED
    assert @instance.submitted?
  end

  test "submitted?() returns false when the stage is not set to SUBMITTED" do
    assert !@instance.submitted?
  end

  # submitting?()

  test "submitting?() returns true when the stage is set to SUBMITTING" do
    @instance.stage = Item::Stages::SUBMITTING
    assert @instance.submitting?
  end

  test "submitting?() returns false when the stage is not set to SUBMITTING" do
    assert !@instance.submitting?
  end

  # temp_embargo_expires_at

  test "temp_embargo_expires_at must be in YYYY-MM-DD format" do
    @instance.temp_embargo_expires_at = "bogus"
    assert !@instance.valid?
    @instance.temp_embargo_expires_at = "2053-05-3"
    assert !@instance.valid?
    @instance.temp_embargo_expires_at = "2053-5-03"
    assert !@instance.valid?
    @instance.temp_embargo_expires_at = "20530503"
    assert !@instance.valid?
    @instance.temp_embargo_expires_at = "2053-05-03"
    assert @instance.valid?
  end

  # temp_embargo_kind

  test "temp_embargo_kind must be a valid value" do
    @instance.temp_embargo_kind = 99
    assert !@instance.valid?
    @instance.temp_embargo_kind = Embargo::Kind::DOWNLOAD
    assert @instance.valid?
  end

  # temp_embargo_type

  test "temp_embargo_type must be a valid value" do
    @instance.temp_embargo_type = "bogus"
    assert !@instance.valid?
    @instance.temp_embargo_type = "open"
    assert @instance.valid?
    @instance.temp_embargo_type = "uofi"
    assert @instance.valid?
    @instance.temp_embargo_type = "closed"
    assert @instance.valid?
  end

  # title() (Describable concern)

  test "title() returns the title element value" do
    item = items(:described)
    assert_equal "Some title", item.title
  end

  test "title() returns an empty string when there is no title element" do
    item = items(:undescribed)
    assert_equal "", item.title
  end

  # update()

  test "update() nillifies stage_reason if it didn't change but the stage did" do
    @instance.update!(stage:        Item::Stages::APPROVED,
                      stage_reason: "Reason 1")
    assert_equal Item::Stages::APPROVED, @instance.stage
    assert_equal "Reason 1", @instance.stage_reason

    @instance.update!(stage: Item::Stages::WITHDRAWN)
    assert_equal Item::Stages::WITHDRAWN, @instance.stage
    assert_nil @instance.stage_reason
  end

  # validate()

  test "validate() ensures that no more than one bitstream is set as primary" do
    assert @instance.validate
    @instance.bitstreams.build(primary: true)
    @instance.bitstreams.build(primary: true)
    assert !@instance.validate
  end

  test "validate() ensures that a submission includes at least one bitstream" do
    item = items(:submitting)
    assert item.validate
    item.bitstreams.destroy_all
    item.stage = Item::Stages::SUBMITTED
    assert !item.validate
  end

  test "validate() ensures that a submission includes all required elements" do
    item = items(:submitting)
    assert item.validate
    item.elements.where(registered_element: registered_elements(:dc_title)).destroy_all
    item.stage = Item::Stages::SUBMITTED
    assert !item.validate
  end

  # withdrawn?()

  test "withdrawn?() returns true when the stage is set to WITHDRAWN" do
    @instance.stage = Item::Stages::WITHDRAWN
    assert @instance.withdrawn?
  end

  test "withdrawn?() returns false when the stage is not set to WITHDRAWN" do
    assert !@instance.withdrawn?
  end

end
