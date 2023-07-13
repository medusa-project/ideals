require 'test_helper'

class ItemTest < ActiveSupport::TestCase

  include ActionMailer::TestHelper

  setup do
    setup_opensearch
    setup_s3
    @instance = items(:uiuc_item1)
  end

  teardown do
    clear_message_queues
  end

  # Stages

  test "Stages.all() returns values in order" do
    assert_equal Item::Stages::all.sort, Item::Stages::all
  end

  # delete_document() (Indexed concern)

  test "delete_document() deletes a document" do
    institution = institutions(:uiuc)
    items = Item.where(institution_id: institution.id)
    items.each(&:reindex)
    refresh_opensearch
    count = Item.search.institution(institution).count
    assert count > 0

    Item.delete_document(items.first.index_id)
    refresh_opensearch
    assert_equal count - 1, Item.search.institution(institution).count
  end

  # index_unindexed() (Indexed concern)

  test "index_unindexed() indexes all unindexed models" do
    Item.index_unindexed
    refresh_opensearch
    assert Item.search.count > 0
  end

  # non_embargoed()

  test "non_embargoed() returns all non-all-access-embargoed items" do
    assert_equal Item.count - Embargo.where(kind: Embargo::Kind::ALL_ACCESS).count,
                 Item.non_embargoed.count
  end

  # reindex_all() (Indexed concern)

  test "reindex_all() reindexes all items" do
    setup_opensearch
    institution = institutions(:uiuc)
    assert_equal 0, Item.search.institution(institution).count

    Item.reindex_all
    refresh_opensearch

    expected = Item.distinct.
      where(institution_id: institution.id).
      where.not(stage: Item::Stages::BURIED).
      count
    actual   = Item.search.institution(institution).count
    assert actual > 0
    assert_equal expected, actual
  end

  # search() (Indexed concern)

  test "search() returns an ItemRelation" do
    assert_kind_of ItemRelation, Item.search.institution(institutions(:uiuc))
  end

  # create_zip_file()

  test "create_zip_file() creates a zip file" do
    setup_s3
    item_ids = [items(:uiuc_approved).id, items(:uiuc_multiple_bitstreams).id]
    dest_key   = "institutions/test/downloads/file.zip"
    Item.create_zip_file(item_ids: item_ids, dest_key: dest_key)

    bucket = ::Configuration.instance.storage[:bucket]
    assert S3Client.instance.head_object(bucket: bucket,
                                         key:    dest_key).content_length > 0
  end

  # all_access_embargoes()

  test "all_access_embargoes() returns all all-access embargoes" do
    assert_equal 0, @instance.all_access_embargoes.length

    @instance = items(:uiuc_embargoed)
    assert_equal 1, @instance.all_access_embargoes.length
  end

  # all_collection_admins()

  test "all_collection_admins() returns the expected users" do
    assert_equal 1, @instance.all_collection_admins.length
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
    item = items(:uiuc_described)
    item.approve
    assert_equal Item::Stages::APPROVED, item.stage
  end

  test "approve() creates an associated date-approved element" do
    item = items(:uiuc_submitting)
    item.institution.update!(handle_uri_element: nil)
    assert_difference "AscribedElement.count", 1 do
      item.approve
      e = item.element(item.institution.date_approved_element.name)
      assert_not_nil e.string
      assert_equal e.registered_element.institution, item.institution
    end
  end

  test "approve() does not create an associated date-approved element if no
  such mapping is defined" do
    item = items(:uiuc_submitting)
    item.institution.update!(date_approved_element: nil,
                             handle_uri_element:    nil)
    assert_no_difference "item.elements.count" do
      item.approve
    end
  end

  test "approve() sets correct bitstream bundle positions" do
    item = items(:uiuc_described)
    item.bitstreams.build(filename: "Test 1", length: 0)
    item.bitstreams.build(filename: "Test 6", length: 0)
    item.bitstreams.build(filename: "Test 5", length: 0)
    item.bitstreams.build(filename: "Test 3", length: 0)
    item.bitstreams.build(filename: "Test 2", length: 0)
    item.bitstreams.build(filename: "Test 4", length: 0)
    item.save!
    item.approve

    filenames = item.bitstreams.map(&:filename)
    NaturalSort.sort!(filenames)
    item.bitstreams.each do |bs|
      assert_equal filenames.index(bs.filename), bs.bundle_position
    end
  end

  include ActionView::Helpers::TextHelper
  test "approve() adds a license.txt bitstream when deposit_agreement is
  present" do
    deposit_agreement = "This is the deposit agreement. It is intentionally "\
                        "longer than 80 columns in order to check the word "\
                        "wrapping."
    item = Item.create!(institution:        institutions(:southwest),
                        primary_collection: collections(:southwest_unit1_collection1),
                        stage:              Item::Stages::APPROVED,
                        deposit_agreement:  deposit_agreement)
    item.approve

    assert_equal 1, item.bitstreams.count
    bs = item.bitstreams.first
    assert_equal "license.txt", bs.filename
    assert_equal "license.txt", bs.original_filename
    assert_equal deposit_agreement.bytesize, bs.length
    assert_equal Bitstream::Bundle::LICENSE, bs.bundle
    assert_nil bs.staging_key
    assert_not_nil bs.permanent_key
    assert_equal word_wrap(deposit_agreement), bs.data.read
  end

  test "approve() does not add a license.txt bitstream when deposit_agreement
  is not present" do
    item = Item.create!(institution:        institutions(:southwest),
                        primary_collection: collections(:southwest_unit1_collection1),
                        stage:              Item::Stages::APPROVED)
    item.approve

    assert_empty item.bitstreams
  end

  test "approve() moves all associated Bitstreams into permanent storage" do
    item    = items(:uiuc_described)
    fixture = file_fixture("escher_lego.png")
    @instance.bitstreams.each do |bs|
      File.open(fixture, "r") do |file|
        bs.upload_to_staging(file)
      end
    end

    item.approve
    assert_equal item.bitstreams.count,
                 item.bitstreams.where.not(permanent_key: nil).count
  end

  test "approve() sends ingest messages to Medusa" do
    # TODO: write this
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
    @instance = items(:uiuc_described)
    # add another title to test handling of multiple same-named elements
    @instance.elements.build(registered_element: registered_elements(:uiuc_dc_title),
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
    @instance = items(:uiuc_item1)
    hash = @instance.as_change_hash
    @instance.bitstreams.each do |bs|
      assert_equal bs.filename, hash["bitstream:#{bs.id}:filename"]
    end
  end

  # as_indexed_json()

  test "as_indexed_json() returns the correct structure" do
    @instance.elements.build(registered_element: registered_elements(:uiuc_dc_title),
                             string:             "test")
    doc = @instance.as_indexed_json
    assert_not_empty doc[Item::IndexFields::ALL_ELEMENTS]
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
    assert_equal @instance.institution.name,
                 doc[Item::IndexFields::INSTITUTION_NAME]
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

    item = items(:uiuc_described)
    doc = item.as_indexed_json
    assert_equal 3, item.elements.length
    title = item.elements.find{ |e| e.name == item.institution.title_element.name }
    assert_equal [title.string],
                 doc[title.registered_element.indexed_field]
  end

  test "as_indexed_json() converts date-type element strings to ISO 8601" do
    reg_e = registered_elements(:uiuc_dc_date_issued)
    @instance.elements.build(registered_element: reg_e,
                             string:             "October 2015").save
    doc = @instance.as_indexed_json
    assert_equal [Date.parse("October 2015").iso8601], doc[reg_e.indexed_field]
  end

  test "as_indexed_json() strips tags from HTML element values" do
    reg_e = registered_elements(:uiuc_dc_description)
    @instance.elements.build(registered_element: reg_e,
                             string:             "<a href=\"href\">Text</a>").save
    doc = @instance.as_indexed_json
    assert_equal ["Text"], doc[reg_e.indexed_field]
  end

  # assign_handle()

  test "assign_handle() does nothing if the instance already has a handle" do
    assert_not_nil @instance.handle
    @instance.assign_handle
  end

  test "assign_handle() assigns a handle" do
    item = items(:uiuc_described)
    item.assign_handle
    assert_not_nil item.handle.suffix
  end

  test "assign_handle() puts the created handle to the server" do
    item = items(:uiuc_described)
    item.handle.destroy!
    item.reload
    item.assign_handle
    assert item.handle.exists_on_server?
  end

  test "assign_handle() creates an associated handle URI element" do
    item = items(:uiuc_described)
    item.handle.destroy!
    item.reload
    assert_difference "AscribedElement.count", 1 do
      item.assign_handle
      e = item.element(item.institution.handle_uri_element.name)
      assert_equal item.handle.permanent_url, e.uri
      assert_equal e.registered_element.institution, item.institution
    end
  end

  test "assign_handle() does not create an associated handle URI element if
  no such mapping is defined" do
    item = items(:uiuc_described)
    item.institution.update!(handle_uri_element: nil)
    assert_no_difference "AscribedElement.count" do
      item.assign_handle
    end
  end

  # authors() (Describable concern)

  test "authors() returns all author elements" do
    item  = items(:uiuc_described)
    reg_e = item.institution.author_element
    item.elements.build(registered_element: reg_e, string: "Value 1")
    item.elements.build(registered_element: reg_e, string: "Value 2")
    assert_equal ["Value 1", "Value 2"], item.authors.map(&:string)
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
    @instance = items(:uiuc_buried)
    @instance.bury!
  end

  # complete_submission()

  test "complete_submission() sets the stage to submitted if the collection is
  reviewing submissions" do
    item = items(:uiuc_described)
    item.primary_collection.submissions_reviewed = true
    item.complete_submission
    assert_equal Item::Stages::SUBMITTED, item.stage
  end

  test "complete_submission() sets the stage to approved if the collection is
  not reviewing submissions" do
    item = items(:uiuc_described)
    item.primary_collection.submissions_reviewed = false
    item.complete_submission
    assert_equal Item::Stages::APPROVED, item.stage
  end

  test "complete_submission() creates an associated date-submitted element" do
    item = items(:uiuc_described)
    item.complete_submission
    e = item.element(item.institution.date_submitted_element.name)
    assert_not_nil e.string
    assert_equal item.institution, e.registered_element.institution
  end

  test "complete_submission() creates an associated date-submitted element
  if the collection is not reviewing submissions" do
    item = items(:uiuc_submitting)
    item.primary_collection.submissions_reviewed = false
    item.institution.update!(date_approved_element: nil,
                             handle_uri_element:    nil)
    assert_difference "AscribedElement.count", 1 do
      item.complete_submission
      e = item.element(item.institution.date_submitted_element.name)
      assert_not_nil e.string
      assert_equal e.registered_element.institution, item.institution
    end
  end

  test "complete_submission() does not create an associated date-submitted
  element if no such mapping is defined" do
    item = items(:uiuc_submitting)
    item.primary_collection.submissions_reviewed = false
    item.institution.update!(date_submitted_element: nil,
                             date_approved_element:  nil,
                             handle_uri_element:     nil)
    assert_no_difference "AscribedElement.count" do
      item.complete_submission
    end
  end

  test "complete_submission() does not move any associated Bitstreams into
  permanent storage if the collection is reviewing submissions" do
    item    = items(:uiuc_described)
    item.primary_collection.submissions_reviewed = true
    fixture = file_fixture("escher_lego.png")
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
    item    = items(:uiuc_described)
    item.primary_collection.submissions_reviewed = false
    fixture = file_fixture("escher_lego.png")
    @instance.bitstreams.each do |bs|
      File.open(fixture, "r") do |file|
        bs.upload_to_staging(file)
      end
    end

    item.complete_submission

    assert_equal item.bitstreams.count,
                 item.bitstreams.where.not(permanent_key: nil).count
  end

  test "complete_submission() creates an associated date-approved element when
  the collection is not reviewing submissions" do
    item = items(:uiuc_submitting)
    item.primary_collection.submissions_reviewed = false
    item.institution.update!(handle_uri_element: nil)

    item.complete_submission
    e = item.element(item.institution.date_approved_element.name)
    assert_not_nil e.string
    assert_equal e.registered_element.institution, item.institution
  end

  test "approve() does not create an associated date-approved element if no
  such mapping is defined and the collection is not reviewing submissions" do
    item = items(:uiuc_submitting)
    item.primary_collection.submissions_reviewed = false
    item.institution.update!(date_approved_element: nil,
                             handle_uri_element:    nil)
    assert_difference "item.elements.count", 1 do # if it were created, we'd expect 2
      item.complete_submission
    end
  end

  test "complete_submission() sets correct bitstream bundle positions when the
  collection is not reviewing submissions" do
    item = items(:uiuc_described)
    item.primary_collection.submissions_reviewed = false
    item.bitstreams.build(filename: "Test 1", length: 0)
    item.bitstreams.build(filename: "Test 6", length: 0)
    item.bitstreams.build(filename: "Test 5", length: 0)
    item.bitstreams.build(filename: "Test 3", length: 0)
    item.bitstreams.build(filename: "Test 2", length: 0)
    item.bitstreams.build(filename: "Test 4", length: 0)
    item.save!
    item.complete_submission

    filenames = item.bitstreams.map(&:filename)
    NaturalSort.sort!(filenames)
    item.bitstreams.each do |bs|
      assert_equal filenames.index(bs.filename), bs.bundle_position
    end
  end

  include ActionView::Helpers::TextHelper
  test "complete_submission() adds a license.txt bitstream when
  deposit_agreement is present and the collection is not reviewing submissions" do
    deposit_agreement = "This is the deposit agreement. It is intentionally "\
                        "longer than 80 columns in order to check the word "\
                        "wrapping."
    item = items(:uiuc_submitting)
    item.primary_collection.submissions_reviewed = false
    item.deposit_agreement = deposit_agreement
    item.complete_submission

    bs = item.bitstreams.find{ |b| b.filename == "license.txt" }
    assert_equal "license.txt", bs.original_filename
    assert_equal deposit_agreement.bytesize, bs.length
    assert_equal Bitstream::Bundle::LICENSE, bs.bundle
    assert_nil bs.staging_key
    assert_not_nil bs.permanent_key
    assert_equal word_wrap(deposit_agreement), bs.data.read
  end

  test "complete_submission() does not add a license.txt bitstream when
  deposit_agreement is not present and the collection is not reviewing
  submissions" do
    item = items(:uiuc_submitting)
    item.primary_collection.submissions_reviewed = false
    item.complete_submission

    assert_nil item.bitstreams.find{ |b| b.filename == "license.txt" }
  end

  test "complete_submission() sends ingest messages to Medusa" do
    # TODO: write this
  end

  # delete_from_permanent_storage()

  test "delete_from_permanent_storage() deletes all associated Bitstreams from
  permanent storage" do
    filename = "escher_lego.png"
    fixture  = file_fixture(filename)
    @instance.bitstreams.each do |bs|
      bs.update!(permanent_key: Bitstream.permanent_key(institution_key: @instance.institution.key,
                                                        item_id:         @instance.id,
                                                        filename:        filename))
      bs.upload_to_permanent(fixture)
    end

    @instance.delete_from_permanent_storage

    assert_equal @instance.bitstreams.count,
                 @instance.bitstreams.where(permanent_key: nil).count
  end

  # destroy()

  test "destroy() fails for in-archive items" do
    item = items(:uiuc_in_medusa)
    assert_raises do
      item.destroy!
    end
  end

  test "destroy() succeeds for not-in-archive items" do
    item = items(:uiuc_submitting)
    item.destroy!
    assert item.destroyed?
  end

  test "destroy() destroys dependent AscribedElements" do
    item = items(:uiuc_described)
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

  test "effective_metadata_profile() returns the global metadata profile if the
  item has no primary collection" do
    @instance.primary_collection = nil
    assert_equal MetadataProfile.global, @instance.effective_metadata_profile
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

  test "effective_submission_profile() returns the owning institution's profile
  if the primary collection's submission profile is not set" do
    institution = @instance.institution
    @instance.collections.destroy_all
    assert_equal institution.default_submission_profile,
                 @instance.effective_submission_profile
  end

  # element() (Describable concern)

  test "element() returns a matching element" do
    assert_equal "Some title", items(:uiuc_described).element("dc:title").string
    assert_equal "Some title", items(:uiuc_described).element(:"dc:title").string
  end

  test "element() returns nil if no such element exists" do
    assert_nil @instance.element("bogus")
  end

  # embargoed_for?()

  test "embargoed_for?() returns false for an item with no embargoes" do
    assert !@instance.embargoed_for?(users(:example))
  end

  test "embargoed_for?() returns false for an item with only a download embargo" do
    @instance.embargoes.build(kind:       Embargo::Kind::DOWNLOAD,
                              expires_at: Time.now + 1.year).save!
    assert !@instance.embargoed_for?(users(:example))
  end

  test "embargoed_for?() returns false for an item with an all-access embargo to
  which the given user is exempt" do
    user    = users(:southwest)
    group   = user_groups(:southwest_unused)
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
    assert @instance.embargoed_for?(users(:example))
  end

  # exhume!()

  test "exhume!() sets the stage to APPROVED" do
    @instance = items(:uiuc_buried)
    @instance.exhume!
    assert_equal Item::Stages::APPROVED, @instance.stage
  end

  test "exhume!() creates an associated Event" do
    @instance = items(:uiuc_buried)
    @instance.exhume!
    assert_equal 1, @instance.events.where(event_type: Event::Type::UNDELETE).count
  end

  test "exhume!() does nothing to a non-buried item" do
    @instance.exhume!
  end

  # ingest_into_medusa()

  test "ingest_into_medusa() does nothing if preservation is not active for the
  owning institution" do
    fixture = file_fixture("escher_lego.png")
    @instance.bitstreams.each do |bs|
      File.open(fixture, "r") do |file|
        bs.upload_to_staging(file)
      end
    end

    @instance.move_into_permanent_storage
    @instance.ingest_into_medusa
  end

  test "ingest_into_medusa() ingests all associated Bitstreams into Medusa" do
    fixture = file_fixture("escher_lego.png")
    @instance.bitstreams.each do |bs|
      File.open(fixture, "r") do |file|
        bs.upload_to_staging(file)
      end
    end

    @instance.move_into_permanent_storage
    @instance.ingest_into_medusa

    queue = @instance.institution.outgoing_message_queue
    AmqpHelper::Connector[:ideals].with_parsed_message(queue) do |message|
      assert_equal "ingest", message['operation']
    end
  end

  # metadata_profile()

  test "metadata_profile() returns the primary collection's effective metadata
  profile" do
    assert_equal metadata_profiles(:uiuc_default), @instance.metadata_profile
  end

  # move_into_permanent_storage()

  test "move_into_permanent_storage() moves all associated Bitstreams into
  permanent storage" do
    fixture = file_fixture("escher_lego.png")
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
    refresh_opensearch

    assert_equal 1, Item.search.
      institution(institutions(:uiuc)).
      filter(Item::IndexFields::ID, @instance.index_id).
      count
  end

  # representative_bitstream()

  test "representative_bitstream() returns the primary bitstream if one exists" do
    @instance = Item.create(institution: institutions(:southwest))
    b1 = @instance.bitstreams.build(primary:  true,
                                    bundle:   Bitstream::Bundle::CONTENT,
                                    filename: "image.jpg")
    b2 = @instance.bitstreams.build(primary:  false,
                                    bundle:   Bitstream::Bundle::LICENSE,
                                    filename: "license.txt")

    assert_same b1, @instance.representative_bitstream
  end

  test "representative_bitstream() returns a bitstream in the content bundle if
  a primary bitstream does not exist" do
    @instance = Item.create(institution: institutions(:southwest))
    b1 = @instance.bitstreams.build(primary:  false,
                                    bundle:   Bitstream::Bundle::CONTENT,
                                    filename: "image.jpg")
    b2 = @instance.bitstreams.build(primary:  false,
                                    bundle:   Bitstream::Bundle::LICENSE,
                                    filename: "license.txt")

    assert_same b1, @instance.representative_bitstream
  end

  test "representative_bitstream() returns nil if no representative bitstream
  exists" do
    @instance = Item.create(institution: institutions(:southwest))
    @instance.bitstreams.build(primary:  false,
                               bundle:   Bitstream::Bundle::NOTES,
                               filename: "notes.txt")
    @instance.bitstreams.build(primary:  false,
                               bundle:   Bitstream::Bundle::LICENSE,
                               filename: "license.txt")

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
    @instance.elements.build(registered_element: registered_elements(:uiuc_dc_title),
                             string:             "Title").save
    assert @instance.required_elements_present?
  end

  # save()

  test "save() prunes duplicate AscribedElements" do
    re = registered_elements(:uiuc_dc_title)
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

  test "save() sends two emails when the stage changes from submitting to
  submitted and the primary collection is reviewing submissions" do
    @instance = items(:uiuc_submitting)
    assert_emails 2 do
      @instance.update!(stage: Item::Stages::SUBMITTED)
    end
  end

  test "save() sends one email when the stage changes from submitting to
  submitted and the primary collection is not reviewing submissions" do
    @instance = items(:uiuc_submitting)
    @instance.primary_collection.update!(submissions_reviewed: false)
    assert_emails 1 do
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
    col = collections(:uiuc_collection2)
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
    @instance = items(:uiuc_buried)
    @instance.collection_item_memberships.destroy_all
    @instance.collections << collections(:uiuc_buried)
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
    @instance.temp_embargo_type = "institution"
    assert @instance.valid?
    @instance.temp_embargo_type = "closed"
    assert @instance.valid?
  end

  # title() (Describable concern)

  test "title() returns the title element value" do
    item = items(:uiuc_described)
    assert_equal "Some title", item.title
  end

  test "title() returns an empty string when there is no title element" do
    item = items(:uiuc_undescribed)
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
    item = items(:uiuc_submitting)
    assert item.validate
    item.bitstreams.destroy_all
    item.stage = Item::Stages::SUBMITTED
    assert !item.validate
  end

  test "validate() ensures that a submission includes all required elements" do
    item = items(:uiuc_submitting)
    assert item.validate
    item.elements.where(registered_element: registered_elements(:uiuc_dc_title)).destroy_all
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
