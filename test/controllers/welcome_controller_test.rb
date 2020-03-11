require 'test_helper'

class WelcomeControllerTest < ActionDispatch::IntegrationTest

  setup do
    setup_elasticsearch
  end

  teardown do
    log_out
  end

  # index()

  test "index() returns HTTP 200" do
    get root_path
    assert_response :ok
  end

  test "index() displays welcome text to logged-out users" do
    get root_path
    assert_select "h1", "Welcome to IDEALS"
  end

  test "index() omits undiscoverable, withdrawn, and submitting items from the item count" do
    Item.reindex_all
    ElasticsearchClient.instance.refresh

    expected_count = Item.where(withdrawn: false,
                                discoverable: true,
                                submitting: false).count

    get root_path
    assert response.body.include?("Search across #{expected_count} items")
  end

  test "index() displays the dashboard to logged-in users" do
    log_in_as(users(:sally))
    get root_path
    assert_select "h1", "Dashboard"
  end

end
