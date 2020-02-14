require 'test_helper'

class ItemsControllerTest < ActionDispatch::IntegrationTest

  teardown do
    log_out
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

  test "show() returns HTTP 410 for withdrawn items" do
    get item_path(items(:withdrawn))
    assert_response :gone
  end

end
