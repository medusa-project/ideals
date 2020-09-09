require 'test_helper'

class BitstreamsControllerTest < ActionDispatch::IntegrationTest

  setup do
    create_bucket
  end

  teardown do
    log_out
  end

  def create_bucket
    client   = Aws::S3::Client.new
    resource = Aws::S3::Resource.new
    bucket   = ::Configuration.instance.aws[:bucket]
    unless resource.bucket(bucket).exists?
      client.create_bucket(bucket: bucket)
    end
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
    skip # TODO: figure out how to POST raw data, i.e. not multipart/form-data
    log_in_as(users(:admin))
    post item_bitstreams_path(items(:item1)),
         file_fixture("escher_lego.jpg")
    assert_response :ok
  end

  test "create() creates a Bitstream" do
    skip # TODO: figure out how to POST raw data, i.e. not multipart/form-data
    log_in_as(users(:admin))
    assert_difference "Bitstream.count" do
      post item_bitstreams_path(items(:item1)),
           file_fixture("escher_lego.jpg")
    end
  end

  test "create() returns HTTP 400 for illegal arguments" do
    skip # TODO: figure out how to POST raw data, i.e. not multipart/form-data
    log_in_as(users(:admin))
    post item_bitstreams_path(items(:item1))
    assert_response :bad_request
  end

  # data()

  test "data() returns HTTP 200" do
    fixture   = file_fixture("escher_lego.jpg")
    item      = items(:item1)
    bitstream = Bitstream.new_in_staging(item,
                                         File.basename(fixture),
                                         File.size(fixture))
    bitstream.save!
    begin
      File.open(fixture, "r") do |file|
        bitstream.upload_to_staging(file)
      end
      get item_bitstream_data_path(item, bitstream)
      assert_response :ok
    ensure
      bitstream.delete_from_staging
    end
  end

  test "data() returns HTTP 403 for submitting items" do
    fixture   = file_fixture("escher_lego.jpg")
    item      = items(:submitting)
    bitstream = Bitstream.new_in_staging(item,
                                         File.basename(fixture),
                                         File.size(fixture))
    bitstream.save!
    begin
      File.open(fixture, "r") do |file|
        bitstream.upload_to_staging(file)
      end
      get item_bitstream_data_path(item, bitstream)
      assert_response :forbidden
    ensure
      bitstream.delete_from_staging
    end
  end

  test "data() returns HTTP 403 for undiscoverable items" do
    fixture   = file_fixture("escher_lego.jpg")
    item      = items(:undiscoverable)
    bitstream = Bitstream.new_in_staging(item,
                                         File.basename(fixture),
                                         File.size(fixture))
    bitstream.save!
    begin
      File.open(fixture, "r") do |file|
        bitstream.upload_to_staging(file)
      end
      get item_bitstream_data_path(item, bitstream)
      assert_response :forbidden
    ensure
      bitstream.delete_from_staging
    end
  end

  test "data() returns HTTP 403 for withdrawn items" do
    fixture   = file_fixture("escher_lego.jpg")
    item      = items(:withdrawn)
    bitstream = Bitstream.new_in_staging(item,
                                         File.basename(fixture),
                                         File.size(fixture))
    bitstream.save!
    begin
      File.open(fixture, "r") do |file|
        bitstream.upload_to_staging(file)
      end
      get item_bitstream_data_path(item, bitstream)
      assert_response :forbidden
    ensure
      bitstream.delete_from_staging
    end
  end

  test "data() respects role limits" do
    fixture   = file_fixture("escher_lego.jpg")
    item      = items(:withdrawn) # (an item that only sysadmins have access to)
    bitstream = Bitstream.new_in_staging(item,
                                         File.basename(fixture),
                                         File.size(fixture))
    bitstream.save!
    begin
      File.open(fixture, "r") do |file|
        bitstream.upload_to_staging(file)
      end

      # Assert that sysadmins can access it
      log_in_as(users(:admin))
      get item_bitstream_data_path(item, bitstream)
      assert_response :ok

      # Assert that role-limited sysadmins can't
      get item_bitstream_data_path(item, bitstream, role: Role::LOGGED_OUT)
      assert_response :forbidden
    ensure
      bitstream.delete_from_staging
    end
  end

  # destroy()

  test "destroy() redirects to login page for logged-out users" do
    delete item_bitstream_path(items(:item1), bitstreams(:item1_in_staging))
    assert_redirected_to login_path
  end

  test "destroy() returns HTTP 403 for unauthorized users" do
    log_in_as(users(:norights))
    delete item_bitstream_path(items(:item1), bitstreams(:item1_in_staging))
    assert_response :forbidden
  end

  test "destroy() destroys the bitstream" do
    log_in_as(users(:admin))
    assert_difference "Bitstream.count", -1 do
      delete item_bitstream_path(items(:item1), bitstreams(:item1_in_staging))
    end
  end

  test "destroy() returns HTTP 204 for an existing bitstream" do
    log_in_as(users(:admin))
    delete item_bitstream_path(items(:item1), bitstreams(:item1_in_staging))
    assert_response :no_content
  end

  test "destroy() returns HTTP 404 for a missing bitstream" do
    log_in_as(users(:admin))
    delete "/items/#{items(:item1).id}/bitstreams/999999"
    assert_response :not_found
  end

  # show()

  test "show() returns HTTP 200" do
    item = items(:item1)
    bs   = bitstreams(:item1_in_staging)
    get item_bitstream_path(item, bs, format: :json)
    assert_response :ok
  end

  test "show() returns HTTP 403 for submitting items" do
    fixture   = file_fixture("escher_lego.jpg")
    item      = items(:submitting)
    bitstream = Bitstream.new_in_staging(item,
                                         File.basename(fixture),
                                         File.size(fixture))
    bitstream.save!
    begin
      File.open(fixture, "r") do |file|
        bitstream.upload_to_staging(file)
      end
      get item_bitstream_path(item, bitstream)
      assert_response :forbidden
    ensure
      bitstream.delete_from_staging
    end
  end

  test "show() returns HTTP 403 for undiscoverable items" do
    fixture   = file_fixture("escher_lego.jpg")
    item      = items(:undiscoverable)
    bitstream = Bitstream.new_in_staging(item,
                                         File.basename(fixture),
                                         File.size(fixture))
    bitstream.save!
    begin
      File.open(fixture, "r") do |file|
        bitstream.upload_to_staging(file)
      end
      get item_bitstream_path(item, bitstream)
      assert_response :forbidden
    ensure
      bitstream.delete_from_staging
    end
  end

  test "show() returns HTTP 403 for withdrawn items" do
    fixture   = file_fixture("escher_lego.jpg")
    item      = items(:withdrawn)
    bitstream = Bitstream.new_in_staging(item,
                                         File.basename(fixture),
                                         File.size(fixture))
    bitstream.save!
    begin
      File.open(fixture, "r") do |file|
        bitstream.upload_to_staging(file)
      end
      get item_bitstream_path(item, bitstream)
      assert_response :forbidden
    ensure
      bitstream.delete_from_staging
    end
  end

  test "show() respects role limits" do
    fixture   = file_fixture("escher_lego.jpg")
    item      = items(:withdrawn) # (an item that only sysadmins have access to)
    bitstream = Bitstream.new_in_staging(item,
                                         File.basename(fixture),
                                         File.size(fixture))
    bitstream.save!
    begin
      File.open(fixture, "r") do |file|
        bitstream.upload_to_staging(file)
      end

      # Assert that sysadmins can access it
      log_in_as(users(:admin))
      get item_bitstream_path(item, bitstream, format: :json)
      assert_response :ok

      # Assert that role-limited sysadmins can't
      get item_bitstream_path(item, bitstream, role: Role::LOGGED_OUT)
      assert_response :forbidden
    ensure
      bitstream.delete_from_staging
    end
  end

end
