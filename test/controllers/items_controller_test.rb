require 'test_helper'

class ItemsControllerTest < ActionDispatch::IntegrationTest

  setup do
    setup_elasticsearch
  end

  teardown do
    log_out
  end

  # destroy()

  test "destroy() redirects to login page for logged-out users" do
    delete item_path(items(:item1))
    assert_redirected_to login_path
  end

  test "destroy() returns HTTP 403 for unauthorized users" do
    log_in_as(users(:norights))
    delete item_path(items(:item1))
    assert_response :forbidden
  end

  test "destroy() destroys the item" do
    log_in_as(users(:admin))
    item = items(:submitting) # a destroyable item
    assert_difference "Item.count", -1 do
      delete item_path(item)
    end
  end

  test "destroy() returns HTTP 302 for an existing item" do
    log_in_as(users(:admin))
    submission = items(:item1)
    delete item_path(submission)
    assert_redirected_to submission.primary_collection
  end

  test "destroy() returns HTTP 404 for a missing item" do
    log_in_as(users(:admin))
    delete "/items/99999"
    assert_response :not_found
  end

  # edit_membership()

  test "edit_membership() redirects to login page for logged-out users" do
    item = items(:item1)
    get item_edit_membership_path(item), xhr: true
    assert_redirected_to login_path
  end

  test "edit_membership() returns HTTP 403 for unauthorized users" do
    log_in_as(users(:norights))
    item = items(:item1)
    get item_edit_membership_path(item), xhr: true
    assert_response :forbidden
  end

  test "edit_membership() returns HTTP 404 for non-XHR requests" do
    log_in_as(users(:admin))
    item = items(:item1)
    get item_edit_membership_path(item)
    assert_response :not_found
  end

  test "edit_membership() returns HTTP 200 for XHR requests" do
    log_in_as(users(:admin))
    item = items(:item1)
    get item_edit_membership_path(item), xhr: true
    assert_response :ok
  end

  # edit_metadata()

  test "edit_metadata() redirects to login page for logged-out users" do
    item = items(:item1)
    get item_edit_metadata_path(item), xhr: true
    assert_redirected_to login_path
  end

  test "edit_metadata() returns HTTP 403 for unauthorized users" do
    log_in_as(users(:norights))
    item = items(:item1)
    get item_edit_metadata_path(item), xhr: true
    assert_response :forbidden
  end

  test "edit_metadata() returns HTTP 404 for non-XHR requests" do
    log_in_as(users(:admin))
    item = items(:item1)
    get item_edit_metadata_path(item)
    assert_response :not_found
  end

  test "edit_metadata() returns HTTP 200 for XHR requests" do
    log_in_as(users(:admin))
    item = items(:item1)
    get item_edit_metadata_path(item), xhr: true
    assert_response :ok
  end

  # edit_properties()

  test "edit_properties() redirects to login page for logged-out users" do
    item = items(:item1)
    get item_edit_properties_path(item), xhr: true
    assert_redirected_to login_path
  end

  test "edit_properties() returns HTTP 403 for unauthorized users" do
    log_in_as(users(:norights))
    item = items(:item1)
    get item_edit_properties_path(item), xhr: true
    assert_response :forbidden
  end

  test "edit_properties() returns HTTP 404 for non-XHR requests" do
    log_in_as(users(:admin))
    item = items(:item1)
    get item_edit_properties_path(item)
    assert_response :not_found
  end

  test "edit_properties() returns HTTP 200 for XHR requests" do
    log_in_as(users(:admin))
    item = items(:item1)
    get item_edit_properties_path(item), xhr: true
    assert_response :ok
  end

  # index()

  test "index() returns HTTP 200 for HTML" do
    get items_path
    assert_response :ok
  end

  test "index() returns HTTP 200 for JSON" do
    get items_path(format: :json)
    assert_response :ok
  end

  test "index() omits submitting, undiscoverable, and withdrawn items by default" do
    Item.reindex_all
    ElasticsearchClient.instance.refresh

    expected_count = Item.where(discoverable: true).
        where.not(stage: [Item::Stages::SUBMITTING, Item::Stages::WITHDRAWN]).
        count

    get items_path(format: :json)
    struct = JSON.parse(response.body)
    assert_equal expected_count, struct['numResults']
  end

  # process_review()

  test "process_review() redirects to login page for logged-out users" do
    post items_process_review_path
    assert_redirected_to login_path
  end

  test "process_review() returns HTTP 403 for unauthorized users" do
    log_in_as(users(:norights))
    post items_process_review_path
    assert_response :forbidden
  end

  test "process_review() redirects to the reivew page for authorized users" do
    log_in_as(users(:admin))
    post items_process_review_path
    assert_redirected_to items_review_path
  end

  test "process_review() approves items" do
    log_in_as(users(:admin))
    item = items(:submitted)
    post items_process_review_path,
         params: {
             items: [item.id],
             verb: "approve"
         }
    assert_redirected_to items_review_path
    item.reload
    assert_equal Item::Stages::APPROVED, item.stage
  end

  test "process_review() creates an associated handle for approved items" do
    item = items(:submitted)
    assert_nil item.handle
    log_in_as(users(:admin))
    post items_process_review_path,
         params: {
             items: [item.id],
             verb: "approve"
         }
    item.reload
    assert_not_nil item.handle
  end

  test "process_review() sends an ingest message to Medusa for approved items" do
    item = items(:submitted)
    log_in_as(users(:admin))
    post items_process_review_path,
         params: {
             items: [item.id],
             verb: "approve"
         }
    item.reload
    item.bitstreams.each do
      AmqpHelper::Connector[:ideals].with_parsed_message(Message.outgoing_queue) do |message|
        assert message.present?
      end
    end
  end

  test "process_review() rejects items" do
    log_in_as(users(:admin))
    item = items(:submitted)
    post items_process_review_path,
         params: {
             items: [item.id],
             verb: "reject"
         }
    assert_redirected_to items_review_path
    item.reload
    assert_equal Item::Stages::REJECTED, item.stage
  end

  # review()

  test "review() redirects to login page for logged-out users" do
    get items_review_path
    assert_redirected_to login_path
  end

  test "review() returns HTTP 403 for unauthorized users" do
    log_in_as(users(:norights))
    get items_review_path
    assert_response :forbidden
  end

  test "review() returns HTTP 200" do
    log_in_as(users(:admin))
    get items_review_path
    assert_response :ok
  end

  # show()

  test "show() returns HTTP 200" do
    get item_path(items(:item1))
    assert_response :ok
  end

  test "show() returns HTTP 200 for JSON" do
    get item_path(items(:item1), format: :json)
    assert_response :ok
  end

  test "show() returns HTTP 403 for submitting items" do
    get item_path(items(:submitting))
    assert_response :forbidden
  end

  test "show() returns HTTP 403 for undiscoverable items" do
    get item_path(items(:undiscoverable))
    assert_response :forbidden
  end

  test "show() returns HTTP 403 for withdrawn items" do
    # TODO: this should arguably return 410 Gone instead.
    get item_path(items(:withdrawn))
    assert_response :forbidden
  end

  test "show() respects role limits" do
    log_in_as(users(:admin))
    get item_path(items(:item1))
    assert_select("dl.properties")

    get item_path(items(:item1), role: Role::LOGGED_OUT)
    assert_select("dl.properties", false)
  end

  # update()

  # TODO: write update() tests

  # upload_bitstreams()

  test "upload_bitstreams() redirects to login page for logged-out users" do
    item = items(:item1)
    get item_upload_bitstreams_path(item), xhr: true
    assert_redirected_to login_path
  end

  test "upload_bitstreams() returns HTTP 403 for unauthorized users" do
    log_in_as(users(:norights))
    item = items(:item1)
    get item_upload_bitstreams_path(item), xhr: true
    assert_response :forbidden
  end

  test "upload_bitstreams() returns HTTP 404 for non-XHR requests" do
    log_in_as(users(:admin))
    item = items(:item1)
    get item_upload_bitstreams_path(item)
    assert_response :not_found
  end

  test "upload_bitstreams() returns HTTP 200 for XHR requests" do
    log_in_as(users(:admin))
    item = items(:item1)
    get item_upload_bitstreams_path(item), xhr: true
    assert_response :ok
  end

end
