require 'test_helper'

class SubmissionsControllerTest < ActionDispatch::IntegrationTest

  setup do
    setup_elasticsearch
    Bitstream.create_bucket
  end

  teardown do
    log_out
  end

  # agreement()

  test "agreement() redirects to login page for logged-out users" do
    get deposit_path
    assert_redirected_to login_path
  end

  test "agreement() returns HTTP 200 for logged-in users" do
    log_in_as(users(:norights))
    get deposit_path
    assert_response :ok
  end

  # complete()

  test "complete() redirects to login page for logged-out users" do
    item = items(:submitting)
    post submission_complete_path(item)
    assert_redirected_to login_path
  end

  test "complete() returns HTTP 200 for logged-in users" do
    item = items(:submitting)
    log_in_as(item.submitter)
    post submission_complete_path(item)
    assert_response :no_content
  end

  test "complete() returns HTTP 302 when an item has already been submitted" do
    item = items(:item1)
    assert !item.submitting
    log_in_as(item.submitter)
    post submission_complete_path(item)
    assert_redirected_to root_path
  end

  test "complete() returns HTTP 400 when the item is missing any required metadata fields" do
    item = items(:submitting)
    item.elements.destroy_all
    log_in_as(item.submitter)
    post submission_complete_path(item)
    assert_response :bad_request
  end

  test "complete() returns HTTP 400 when the item has no associated bitstreams" do
    item = items(:submitting)
    item.bitstreams.destroy_all
    log_in_as(item.submitter)
    post submission_complete_path(item)
    assert_response :bad_request
  end

  test "complete() creates an associated handle" do
    item = items(:submitting)
    assert_nil item.handle
    log_in_as(item.submitter)
    post submission_complete_path(item)

    item.reload
    assert_not_nil item.handle
  end

  test "complete() sends an ingest message to Medusa" do
    item = items(:submitting)
    assert_nil item.handle
    log_in_as(item.submitter)
    post submission_complete_path(item)

    item.reload
    item.bitstreams.each do
      AmqpHelper::Connector[:ideals].with_parsed_message(Message.outgoing_queue) do |message|
        assert message.present?
      end
    end
  end

  test "complete() updates the item's submitting attribute" do
    item = items(:submitting)
    assert item.submitting
    log_in_as(item.submitter)
    post submission_complete_path(item)

    item.reload
    assert !item.submitting
  end

  # create()

  test "create() redirects to login page for logged-out users" do
    post submissions_path
    assert_redirected_to login_path
  end

  test "create() creates an item" do
    log_in_as(users(:admin))
    assert_difference "Item.count" do
      post submissions_path
      item = Item.order(created_at: :desc).first
      assert item.submitting
      assert !item.discoverable
      assert !item.withdrawn
    end
  end

  test "create() redirects to item-edit view" do
    log_in_as(users(:admin))
    post submissions_path
    submission = Item.order(created_at: :desc).limit(1).first
    assert_redirected_to edit_submission_path(submission)
  end

  # destroy()

  test "destroy() redirects to login page for logged-out users" do
    delete submission_path(items(:submitting))
    assert_redirected_to login_path
  end

  test "destroy() returns HTTP 403 for unauthorized users" do
    log_in_as(users(:norights))
    delete submission_path(items(:submitting))
    assert_response :forbidden
  end

  test "destroy() destroys the item" do
    log_in_as(users(:admin))
    item = items(:submitting)
    assert_difference "Item.count", -1 do
      delete submission_path(item)
    end
  end

  test "destroy() returns HTTP 302 for an existing item" do
    log_in_as(users(:admin))
    submission = items(:submitting)
    delete submission_path(submission)
    assert_redirected_to root_path
  end

  test "destroy() returns HTTP 404 for a missing item" do
    log_in_as(users(:admin))
    delete "/submissions/99999"
    assert_response :not_found
  end

  test "destroy() redirects back when an item has already been submitted" do
    log_in_as(users(:admin))
    item = items(:item1)
    delete submission_path(item)
    assert_redirected_to root_url
  end

  # edit()

  test "edit() redirects to login page for logged-out users" do
    item = items(:submitting)
    get edit_submission_path(item)
    assert_redirected_to login_path
  end

  test "edit() returns HTTP 200 for logged-in users" do
    item = items(:submitting)
    log_in_as(item.submitter)
    get edit_submission_path(item)
    assert_response :ok
  end

  test "edit() redirects back when an item has already been submitted" do
    item = items(:item1)
    log_in_as(item.submitter)
    get edit_submission_path(item)
    assert_redirected_to root_path
  end

  # update()

  test "update() redirects to login page for logged-out users" do
    item = items(:submitting)
    patch submission_path(item)
    assert_redirected_to login_path
  end

  test "update() returns HTTP 403 for unauthorized users" do
    log_in_as(users(:norights))
    item = items(:submitting)
    patch submission_path(item)
    assert_response :forbidden
  end

  test "update() updates an item" do
    log_in_as(users(:admin))
    collection = collections(:empty)
    item       = items(:submitting)
    patch submission_path(item),
          xhr: true,
          params: {
              item: {
                  primary_collection_id: collection.id
              }
          }
    item.reload
    assert_equal collection.id, item.primary_collection_id
  end

  test "update() returns HTTP 204" do
    log_in_as(users(:admin))
    item = items(:submitting)
    patch submission_path(item),
          xhr: true,
          params: {
              item: {
                  primary_collection_id: collections(:empty).id
              }
          }
    assert_response :no_content
  end

  test "update() returns HTTP 400 for illegal arguments" do
    log_in_as(users(:admin))
    item = items(:submitting)
    patch submission_path(item),
          xhr: true,
          params: {
              item: {
                  primary_collection_id: 99999
              }
          }
    assert_response :bad_request
  end

  test "update() returns HTTP 404 for nonexistent items" do
    log_in_as(users(:admin))
    patch "/submissions/bogus"
    assert_response :not_found
  end

  test "update() redirects back when an item has already been submitted" do
    log_in_as(users(:admin))
    item = items(:item1)
    patch submission_path(item)
    assert_redirected_to root_url
  end

end
