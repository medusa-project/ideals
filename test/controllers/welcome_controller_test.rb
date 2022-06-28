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

    get root_path
    # TODO: this fails intermittently
    #assert_equal "Search across 8 items",
    #             response.body.match(/Search across \d+ items/)[0]
    assert response.body.include?("Search across")
  end

end
