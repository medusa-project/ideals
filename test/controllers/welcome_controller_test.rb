require 'test_helper'

class WelcomeControllerTest < ActionDispatch::IntegrationTest

  teardown do
    log_out
  end

  # index()

  test "index() returns HTTP 200" do
    get root_path
    assert_response :ok
  end

  test "index() omits undiscoverable, withdrawn, and not-in-archive items from the item count" do
    Item.reindex_all
    ElasticsearchClient.instance.refresh

    expected_count = Item.where(withdrawn: false,
                                discoverable: true,
                                in_archive: true).count

    get root_path
    assert response.body.include?("Search across #{expected_count} items")
  end

end
