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

  test "index() includes only approved items in the count" do
    setup_elasticsearch
    Item.reindex_all
    refresh_elasticsearch

    expected_count = Item.
      where(discoverable: true,
            stage:        Item::Stages::APPROVED).
      count

    get root_path
    assert_equal "Search across #{expected_count} items",
                 response.body.match(/Search across \d+ items/)[0]
  end

end
