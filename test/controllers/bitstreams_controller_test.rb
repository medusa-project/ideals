require 'test_helper'

class BitstreamsControllerTest < ActionDispatch::IntegrationTest

  teardown do
    log_out
  end

  # create()

  test "create() redirects to login page for logged-out users" do
    post item_bitstreams_path(items(:item1))
    assert_redirected_to login_path
  end

  test "create() returns HTTP 403 for unauthorized users" do
    log_in_as(users(:norights))
    post item_bitstreams_path(items(:item1))
    assert_response :forbidden
  end

  test "create() returns HTTP 200" do
    skip # TODO: figure out how to POST raw data
    log_in_as(users(:admin))
    post item_bitstreams_path(items(:item1)),
         file_fixture("escher_lego.jpg")
    assert_response :ok
  end

  test "create() creates a Bitstream" do
    skip # TODO: figure out how to POST raw data
    log_in_as(users(:admin))
    assert_difference "Bitstream.count" do
      post item_bitstreams_path(items(:item1)),
           file_fixture("escher_lego.jpg")
    end
  end

  test "create() returns HTTP 400 for illegal arguments" do
    skip # TODO: figure out how to POST raw data
    log_in_as(users(:admin))
    post item_bitstreams_path(items(:item1)), {}
    assert_response :bad_request
  end

  # destroy()

  test "destroy() redirects to login page for logged-out users" do
    delete item_bitstream_path(items(:item1), bitstreams(:item1_jpg))
    assert_redirected_to login_path
  end

  test "destroy() returns HTTP 403 for unauthorized users" do
    log_in_as(users(:norights))
    delete item_bitstream_path(items(:item1), bitstreams(:item1_jpg))
    assert_response :forbidden
  end

  test "destroy() destroys the bitstream" do
    log_in_as(users(:admin))
    assert_difference "Bitstream.count", -1 do
      delete item_bitstream_path(items(:item1), bitstreams(:item1_jpg))
    end
  end

  test "destroy() returns HTTP 204 for an existing bitstream" do
    log_in_as(users(:admin))
    delete item_bitstream_path(items(:item1), bitstreams(:item1_jpg))
    assert_response :no_content
  end

  test "destroy() returns HTTP 404 for a missing bitstream" do
    log_in_as(users(:admin))
    delete "/items/#{items(:item1).id}/bitstreams/999999"
    assert_response :not_found
  end

end
