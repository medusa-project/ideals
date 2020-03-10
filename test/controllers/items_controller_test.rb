require 'test_helper'

class ItemsControllerTest < ActionDispatch::IntegrationTest

  setup do
    setup_elasticsearch
  end

  teardown do
    log_out
  end

  # destroy()

  test "destroy() redirects to login path for logged-out users" do
    delete item_path(items(:item1))
    assert_redirected_to login_path
  end

  test "destroy() redirects to login path for unauthorized users" do
    log_in_as(users(:norights))
    delete item_path(items(:item1))
    assert_redirected_to login_path
  end

  test "destroy() destroys the item" do
    log_in_as(users(:admin))
    item = items(:item1)
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

  # edit_metadata()

  test "edit_metadata() redirects to login path for logged-out users" do
    item = items(:item1)
    get "/items/#{item.id}/edit-metadata", {}
    assert_redirected_to login_path
  end

  test "edit_metadata() redirects to login path for unauthorized users" do
    log_in_as(users(:norights))
    item = items(:item1)
    get "/items/#{item.id}/edit-metadata", {}
    assert_redirected_to login_path
  end

  test "edit_metadata() returns HTTP 200" do
    log_in_as(users(:admin))
    item = items(:item1)
    get item_edit_metadata_path(item)
    assert_response :ok
  end

  # edit_properties()

  test "edit_properties() redirects to login path for logged-out users" do
    item = items(:item1)
    get "/items/#{item.id}/edit-properties", {}
    assert_redirected_to login_path
  end

  test "edit_properties() redirects to login path for unauthorized users" do
    log_in_as(users(:norights))
    item = items(:item1)
    get "/items/#{item.id}/edit-properties", {}
    assert_redirected_to login_path
  end

  test "edit_properties() returns HTTP 200" do
    log_in_as(users(:admin))
    item = items(:item1)
    get item_edit_properties_path(item)
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

  test "index() omits undiscoverable, withdrawn, and not-in-archive items by default" do
    Item.reindex_all
    ElasticsearchClient.instance.refresh

    expected_count = Item.where(withdrawn: false,
                                discoverable: true,
                                in_archive: true).count

    get items_path(format: :json)
    struct = JSON.parse(response.body)
    assert_equal expected_count, struct['numResults']
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

  test "show() returns HTTP 403 for not-in-archive items" do
    get item_path(items(:not_in_archive))
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

  # update()

  # TODO: write update() tests

end
