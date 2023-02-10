require 'test_helper'

class HandlesControllerTest < ActionDispatch::IntegrationTest

  # redirect()

  test "redirect() returns HTTP 404 for an unrecognized handle prefix" do
    get redirect_handle_path(9999, 9999)
    assert_response :not_found
  end

  test "redirect() returns HTTP 404 for an unrecognized handle suffix" do
    prefix = ::Configuration.instance.handles[:prefix]
    get redirect_handle_path(prefix, 9999)
    assert_response :not_found
  end

  test "redirect() redirects to the relevant resource via  HTTP 301" do
    prefix = ::Configuration.instance.handles[:prefix]
    handle = handles(:uiuc_item1)
    get redirect_handle_path(prefix, handle.suffix)
    assert_response :moved_permanently
    assert_redirected_to handle.item
  end

end
