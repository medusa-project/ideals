require "test_helper"

##
# Tests the multi-step file upload flow as it happens from both the submission
# form and the item view edit-bitstreams modal.
#
class FileUploadTest < ActionDispatch::IntegrationTest

  setup do
    @institution = institutions(:southwest)
    host! @institution.fqdn
    setup_s3
  end

  test "uploading a file to a submitting item" do
    file   = file_fixture("crane.jpg")
    length = File.size(file)
    store  = ObjectStore.instance
    item   = items(:southwest_unit1_collection1_submitting)

    log_in_as(users(:southwest_admin))

    # Create a bitstream
    assert_difference "Bitstream.count" do
      post item_bitstreams_path(item), params: {
        bitstream: {
          filename: "new.jpg",
          length:   length
        }
      }
    end
    assert_response :created

    # Fetch its JSON representation
    get response.header['Location']
    assert_response :ok

    # Upload data to its presigned URL
    struct   = JSON.parse(response.body)
    response = HTTPClient.new.put(struct['presigned_upload_url'], file, {})
    assert_equal 200, response.status

    # Assert that everything is in order
    bitstream = Bitstream.find(struct['id'])
    assert_equal item, bitstream.item
    assert_equal length, bitstream.length
    assert_equal length, store.object_length(key: bitstream.staging_key)
  end

  test "uploading a file to an approved item" do
    file   = file_fixture("crane.jpg")
    length = File.size(file)
    store  = ObjectStore.instance
    item   = items(:southwest_unit1_collection1_item1)

    log_in_as(users(:southwest_admin))

    # Create a bitstream
    assert_difference "Bitstream.count" do
      post item_bitstreams_path(item), params: {
        bitstream: {
          filename: "new.jpg",
          length:   length
        }
      }
    end
    assert_response :created

    # Fetch its JSON representation
    get response.header['Location']
    assert_response :ok

    # Upload data to its presigned URL
    struct   = JSON.parse(response.body)
    response = HTTPClient.new.put(struct['presigned_upload_url'], file, {})
    assert_equal 200, response.status

    # Assert that everything is in order
    bitstream = Bitstream.find(struct['id'])
    assert_equal item, bitstream.item
    assert_equal length, bitstream.length
    assert_equal length, store.object_length(key: bitstream.permanent_key)
  end

end
