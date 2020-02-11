require 'test_helper'

class ItemsControllerTest < ActionDispatch::IntegrationTest

  teardown do
    log_out
  end

  # index()

  test "index() returns HTTP 200" do
    get items_path
    assert_response :ok
  end

  # show()

  test "show() returns HTTP 200" do
    get item_path(items(:item1))
    assert_response :ok
  end

end
