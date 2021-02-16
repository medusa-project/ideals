require 'test_helper'

class BitstreamsControllerTest < ActionDispatch::IntegrationTest

  setup do
    Bitstream.create_bucket
  end

  teardown do
    AmqpHelper::Connector[:ideals].clear_queues(Message.outgoing_queue)
    log_out
  end

  # create()

  test "create() redirects to login page for logged-out users" do
    post item_bitstreams_path(items(:item1))
    assert_redirected_to login_path
  end

  test "create() returns HTTP 200" do
    skip # TODO: figure out how to POST raw data, i.e. not multipart/form-data
    log_in_as(users(:local_sysadmin))
    post item_bitstreams_path(items(:item1)),
         file_fixture("escher_lego.jpg")
    assert_response :ok
  end

  test "create() creates a Bitstream" do
    skip # TODO: figure out how to POST raw data, i.e. not multipart/form-data
    log_in_as(users(:local_sysadmin))
    assert_difference "Bitstream.count" do
      post item_bitstreams_path(items(:item1)),
           file_fixture("escher_lego.jpg")
    end
  end

  test "create() returns HTTP 400 for illegal arguments" do
    skip # TODO: figure out how to POST raw data, i.e. not multipart/form-data
    log_in_as(users(:local_sysadmin))
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

  test "data() increments the bitstream's download count" do
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
      bitstream.reload
      assert_equal 1, bitstream.download_count
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

  test "data() returns HTTP 404 for missing bitstreams" do
    get item_bitstream_data_path(items(:item1), 9999999)
    assert_response :not_found
  end

  test "data() returns HTTP 500 when the underlying data is missing" do
    item      = items(:item1)
    bitstream = Bitstream.new_in_staging(item, "cats.jpg", 234234)
    bitstream.exists_in_staging = true
    bitstream.save!
    get item_bitstream_data_path(item, bitstream)
    assert_response :internal_server_error
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
      log_in_as(users(:local_sysadmin))
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
    log_in_as(users(:local_sysadmin))
    assert_difference "Bitstream.count", -1 do
      delete item_bitstream_path(items(:item1), bitstreams(:item1_in_staging))
    end
  end

  test "destroy() returns HTTP 204 for an existing bitstream" do
    log_in_as(users(:local_sysadmin))
    delete item_bitstream_path(items(:item1), bitstreams(:item1_in_staging))
    assert_response :no_content
  end

  test "destroy() returns HTTP 404 for a missing bitstream" do
    log_in_as(users(:local_sysadmin))
    delete "/items/#{items(:item1).id}/bitstreams/999999"
    assert_response :not_found
  end

  # edit()

  test "edit() redirects to login page for logged-out users" do
    item      = items(:item1)
    bitstream = item.bitstreams.first
    get edit_item_bitstream_path(item, bitstream), xhr: true
    assert_redirected_to login_path
  end

  test "edit() returns HTTP 403 for unauthorized users" do
    log_in_as(users(:norights))
    item      = items(:item1)
    bitstream = item.bitstreams.first
    get edit_item_bitstream_path(item, bitstream), xhr: true
    assert_response :forbidden
  end

  test "edit() returns HTTP 404 for non-XHR requests" do
    log_in_as(users(:local_sysadmin))
    item      = items(:item1)
    bitstream = item.bitstreams.first
    get edit_item_bitstream_path(item, bitstream)
    assert_response :not_found
  end

  test "edit() returns HTTP 200 for XHR requests" do
    log_in_as(users(:local_sysadmin))
    item      = items(:item1)
    bitstream = item.bitstreams.first
    get edit_item_bitstream_path(item, bitstream), xhr: true
    assert_response :ok
  end

  # ingest()

  test "ingest() redirects to login page for logged-out users" do
    post item_bitstream_ingest_path(items(:item1), bitstreams(:item1_in_staging))
    assert_redirected_to login_path
  end

  test "ingest() returns HTTP 403 for unauthorized users" do
    log_in_as(users(:norights))
    post item_bitstream_ingest_path(items(:item1), bitstreams(:item1_in_staging))
    assert_response :forbidden
  end

  test "ingest() returns HTTP 400 if the bitstream's staging key is nil" do
    log_in_as(users(:local_sysadmin))
    bitstream = bitstreams(:item1_in_staging)
    bitstream.update!(exists_in_staging: false, staging_key: nil)
    post item_bitstream_ingest_path(items(:item1), bitstream)
    assert_response :bad_request
  end

  test "ingest() returns HTTP 400 if the bitstream's item does not have a handle" do
    log_in_as(users(:local_sysadmin))
    bitstream = bitstreams(:item1_in_staging)
    item = bitstream.item
    item.handle.destroy!
    item.update!(handle: nil)
    post item_bitstream_ingest_path(items(:item1), bitstream)
    assert_response :bad_request
  end

  test "ingest() returns HTTP 409 if the bitstream has already been submitted for ingest" do
    log_in_as(users(:local_sysadmin))
    bitstream = bitstreams(:item1_in_staging)
    bitstream.update!(submitted_for_ingest: true)
    post item_bitstream_ingest_path(items(:item1), bitstream)
    assert_response :conflict
  end

  test "ingest() returns HTTP 409 if the bitstream already exists in Medusa" do
    log_in_as(users(:local_sysadmin))
    bitstream = bitstreams(:item1_in_staging)
    bitstream.update!(medusa_uuid: SecureRandom.uuid)
    post item_bitstream_ingest_path(items(:item1), bitstream)
    assert_response :conflict
  end

  test "ingest() ingests the bitstream" do
    log_in_as(users(:local_sysadmin))
    bitstream = bitstreams(:item1_in_staging)
    assert !bitstream.submitted_for_ingest

    post item_bitstream_ingest_path(items(:item1), bitstream)
    bitstream.reload
    assert bitstream.submitted_for_ingest
  end

  test "ingest() returns HTTP 204 for a successful ingest" do
    log_in_as(users(:local_sysadmin))
    post item_bitstream_ingest_path(items(:item1), bitstreams(:item1_in_staging))
    assert_response :no_content
  end

  test "ingest() returns HTTP 404 for a missing bitstream" do
    log_in_as(users(:local_sysadmin))
    post "/items/#{items(:item1).id}/bitstreams/999999/ingest"
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
      log_in_as(users(:local_sysadmin))
      get item_bitstream_path(item, bitstream, format: :json)
      assert_response :ok

      # Assert that role-limited sysadmins can't
      get item_bitstream_path(item, bitstream, role: Role::LOGGED_OUT)
      assert_response :forbidden
    ensure
      bitstream.delete_from_staging
    end
  end

  # update()

  test "update() redirects to login page for logged-out users" do
    bitstream = bitstreams(:item1_in_staging)
    patch item_bitstream_path(bitstream.item, bitstream)
    assert_redirected_to login_path
  end

  test "update() returns HTTP 403 for unauthorized users" do
    log_in_as(users(:norights))
    bitstream = bitstreams(:item1_in_staging)
    patch item_bitstream_path(bitstream.item, bitstream)
    assert_response :forbidden
  end
  
  test "update() updates a bitstream" do
    log_in_as(users(:local_sysadmin))
    bitstream = bitstreams(:item1_in_staging)
    patch item_bitstream_path(bitstream.item, bitstream),
          xhr: true,
          params: {
              bitstream: {
                  role: Role::UNIT_ADMINISTRATOR
              }
          }
    bitstream.reload
    assert_equal Role::UNIT_ADMINISTRATOR, bitstream.role
  end

  test "update() creates an associated Event" do
    log_in_as(users(:local_sysadmin))
    bitstream = bitstreams(:item1_in_staging)
    assert_difference "Event.count" do
      patch item_bitstream_path(bitstream.item, bitstream),
            xhr: true,
            params: {
              bitstream: {
                role: Role::UNIT_ADMINISTRATOR
              }
            }
    end
  end

  test "update() returns HTTP 200" do
    log_in_as(users(:local_sysadmin))
    bitstream = bitstreams(:item1_in_staging)
    patch item_bitstream_path(bitstream.item, bitstream),
          xhr: true,
          params: {
              bitstream: {
                  role: Role::UNIT_ADMINISTRATOR
              }
          }
    assert_response :ok
  end

  test "update() returns HTTP 400 for illegal arguments" do
    log_in_as(users(:local_sysadmin))
    bitstream = bitstreams(:item1_in_staging)
    patch item_bitstream_path(bitstream.item, bitstream),
          xhr: true,
          params: {
              bitstream: {
                  role: 9999
              }
          }
    assert_response :bad_request
  end

  test "update() returns HTTP 404 for nonexistent collections" do
    log_in_as(users(:local_sysadmin))
    patch "/items/#{items(:item1).id}/bitstreams/bogus"
    assert_response :not_found
  end

end
