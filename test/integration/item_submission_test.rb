require "test_helper"

##
# Tests that the item submission process produces a correct item.
#
class ItemSubmissionTest < ActionDispatch::IntegrationTest

  setup do
    @institution = institutions(:southwest)
    host! @institution.fqdn
    @collection  = collections(:southwest_unit1_collection1)
    @user        = users(:southwest)
    @collection.submitting_users << @user
    @collection.save!
    log_in_as(@user)
    setup_s3
    setup_opensearch
    clear_message_queues
  end

  teardown do
    clear_message_queues
  end

  test "submitting an item with no embargo to a collection that is not
  reviewing submissions" do
    @collection.update!(submissions_reviewed: false)
    create_item
    ascribe_no_embargo
    ascribe_metadata
    upload_files
    complete_submission

    check_item
    check_no_embargo
    check_bitstreams
    check_messages
  end

  test "submitting an item with an institution-only embargo to a collection
  that is not reviewing submissions" do
    @collection.update!(submissions_reviewed: false)
    create_item
    ascribe_institution_embargo
    ascribe_metadata
    upload_files
    complete_submission

    check_item
    check_institution_embargo
    check_bitstreams
    check_messages
  end

  test "submitting an item with a closed embargo to a collection that is not
  reviewing submissions" do
    @collection.update!(submissions_reviewed: false)
    create_item
    ascribe_closed_embargo
    ascribe_metadata
    upload_files
    complete_submission

    check_item
    check_closed_embargo
    check_bitstreams
    check_messages
  end

  test "submitting an item with a closed embargo, and suppressing records from
  public access, to a collection that is not reviewing submissions" do
    @collection.update!(submissions_reviewed: false)
    create_item
    ascribe_all_access_embargo
    ascribe_metadata
    upload_files
    complete_submission

    check_item
    check_all_access_embargo
    check_bitstreams
    check_messages
  end

  test "submitting an item with no embargo to a collection that is reviewing
  submissions" do
    @collection.update!(submissions_reviewed: true)
    create_item
    ascribe_no_embargo
    ascribe_metadata
    upload_files
    complete_submission

    check_item
    check_no_embargo
    check_bitstreams
    check_messages
  end

  test "submitting an item with no files" do
    @collection.update!(submissions_reviewed: false)
    create_item
    ascribe_no_embargo
    ascribe_metadata
    post submission_complete_path(@item)
    assert_redirected_to edit_submission_path(@item)
  end


  private

  def create_item
    assert_difference "Item.count" do
      assert_difference "Event.count" do
        post submissions_path, params: {
          primary_collection_id: @collection.id
        }
      end
    end
    @item = Item.order(created_at: :desc).limit(1).first
    assert_redirected_to edit_submission_path(@item)

    # Check the item
    assert_equal @institution, @item.institution
    assert_equal @collection, @item.primary_collection
    assert_equal @user, @item.submitter
    assert_equal Item::Stages::SUBMITTING, @item.stage

    # Check the event
    @event = Event.order(created_at: :desc).limit(1).first
    assert_equal Event::Type::CREATE, @event.event_type
    assert_equal @item, @event.item
    assert_equal @user, @event.user
    assert_equal @item.as_change_hash, @event.after_changes
    assert @event.description.start_with?("Item created")
  end

  def ascribe_no_embargo
    patch submission_path(@item), params: {
      item: { temp_embargo_type: "open" }
    }
  end

  def ascribe_institution_embargo
    patch submission_path(@item), params: {
      item: { temp_embargo_type: "institution" }
    }
  end

  def ascribe_closed_embargo
    patch submission_path(@item), params: {
      item: {
        temp_embargo_type:       "closed",
        temp_embargo_expires_at: "2095-02-03",
        temp_embargo_reason:     "Why not"
      }
    }
  end

  def ascribe_all_access_embargo
    patch submission_path(@item), params: {
      item: {
        temp_embargo_type:       "closed",
        temp_embargo_expires_at: "2095-02-03",
        temp_embargo_reason:     "Why not",
        temp_embargo_kind:       Embargo::Kind::ALL_ACCESS
      }
    }
  end

  def ascribe_metadata
    elements = []
    @institution.default_submission_profile.elements.select(&:required).map(&:name).each do |name|
      elements << { name: name }
      elements << { string: "Test" }
    end

    patch submission_path(@item), params: {
      item: {
        stage: Item::Stages::SUBMITTING # only because item is required in the params
      },
      elements: elements
    }
  end

  def upload_files
    file   = file_fixture("crane.jpg")
    length = File.size(file)
    store  = ObjectStore.instance

    # Create a bitstream
    assert_difference "Bitstream.count" do
      post item_bitstreams_path(@item), params: {
        bitstream: {
          filename: "new.jpg",
          length:   length
        }
      }
    end
    assert_response :created

    # Fetch its JSON representation
    get response.header['Location']
    assert_response :ok

    # Upload data to its presigned URL
    struct   = JSON.parse(response.body)
    response = HTTPClient.new.put(struct['presigned_upload_url'], file, {})
    assert_equal 200, response.status

    # Assert that everything is in order
    bitstream = Bitstream.find(struct['id'])
    assert_equal @item, bitstream.item
    assert_equal length, bitstream.length
    assert_equal length, store.object_length(key: bitstream.staging_key)
  end

  def complete_submission
    assert_difference "Event.count" do
      post submission_complete_path(@item)
      if @item.primary_collection.submissions_reviewed
        assert_redirected_to submission_status_path(@item)
        assert flash['success'].blank?
      else
        assert_redirected_to item_path(@item)
        assert flash['success'].start_with?("Your submission is complete")
      end
    end
    @item.reload
  end

  def check_item
    if @item.primary_collection.submissions_reviewed
      assert_equal Item::Stages::SUBMITTED, @item.stage
    else
      assert_equal Item::Stages::APPROVED, @item.stage
    end
    assert_equal "Test", @item.effective_title
  end

  def check_no_embargo
    assert_empty @item.embargoes
  end

  def check_institution_embargo
    embargo = @item.embargoes.first
    assert_equal Embargo::Kind::DOWNLOAD, embargo.kind
    assert_equal @institution.defining_user_group, embargo.user_groups.first
    assert embargo.perpetual
  end

  def check_closed_embargo
    embargo = @item.embargoes.first
    assert_equal Embargo::Kind::DOWNLOAD, embargo.kind
    assert_equal "2095-02-03", embargo.expires_at.strftime("%Y-%m-%d")
    assert_equal "Why not", embargo.reason
    assert_empty embargo.user_groups
    assert !embargo.perpetual
  end

  def check_all_access_embargo
    embargo = @item.embargoes.first
    assert_equal Embargo::Kind::ALL_ACCESS, embargo.kind
    assert_equal "2095-02-03", embargo.expires_at.strftime("%Y-%m-%d")
    assert_equal "Why not", embargo.reason
    assert_empty embargo.user_groups
    assert !embargo.perpetual
  end

  def check_bitstreams
    bitstream = @item.bitstreams.first
    if @item.primary_collection.submissions_reviewed
      assert_not_nil bitstream.staging_key
      assert_nil bitstream.permanent_key
    else
      assert_nil bitstream.staging_key
      assert_not_nil bitstream.permanent_key
    end
    assert_equal "new.jpg", bitstream.original_filename
    assert_equal bitstream.original_filename, bitstream.filename
    assert_not_nil bitstream.length
  end

  def check_messages
    AmqpHelper::Connector[:ideals].with_parsed_message(@institution.outgoing_message_queue) do |message|
      if @item.primary_collection.submissions_reviewed
        assert_nil message
      else
        bitstream = @item.bitstreams.first
        assert_equal "ingest", message['operation']
        assert_not_nil message['staging_key']
        assert_not_nil message['target_key']
        assert_equal bitstream.class.to_s, message['pass_through']['class']
        assert_equal bitstream.id, message['pass_through']['identifier']
      end
    end
  end

end
