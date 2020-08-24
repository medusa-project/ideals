require 'test_helper'

class BitstreamTest < ActiveSupport::TestCase

  setup do
    @instance = bitstreams(:item1_jpg)
    assert @instance.valid?
    create_bucket
  end

  teardown do
    AmqpHelper::Connector[:ideals].clear_queues(MedusaIngest.outgoing_queue)
  end

  def create_bucket
    client   = Aws::S3::Client.new
    resource = Aws::S3::Resource.new
    bucket   = ::Configuration.instance.aws[:bucket]
    unless resource.bucket(bucket).exists?
      client.create_bucket(bucket: bucket)
    end
  end

  # medusa_key()

  test "medusa_key() raises an error if the handle argument is blank" do
    assert_raises ArgumentError do
      Bitstream.medusa_key("", "cats.jpg")
    end
  end

  test "medusa_key() raises an error if the filename argument is blank" do
    assert_raises ArgumentError do
      Bitstream.medusa_key("handle", "")
    end
  end

  test "medusa_key() returns a correct key" do
    assert_equal "handle/cats.jpg",
                 Bitstream.medusa_key("handle", "cats.jpg")
  end

  # new_in_staging()

  test "new_in_staging() returns a correct instance" do
    item     = items(:item1)
    filename = "cats.jpg"
    length   = 3424
    bs       = Bitstream.new_in_staging(item, filename, length)
    assert_equal Bitstream.staging_key(item.id, filename), bs.staging_key
    assert_equal length, bs.length
    assert_equal filename, bs.original_filename
    assert_nil bs.media_type
  end

  # staging_key()

  test "staging_key() returns a correct key" do
    assert_equal "#{Bitstream::STAGING_KEY_PREFIX}/30/cats.jpg",
                 Bitstream.staging_key(30, "cats.jpg")
  end

  # delete_from_staging()

  test "delete_from_staging() does nothing if the instance has no corresponding object" do
    @instance.delete_from_staging # assert no errors
  end

  test "delete_from_staging() deletes the corresponding object" do
    # Write a file to the bucket.
    fixture = file_fixture("escher_lego.jpg")
    File.open(fixture, "r") do |file|
      @instance = Bitstream.new_in_staging(items(:item1),
                                           File.basename(fixture),
                                           File.size(fixture))
      @instance.upload_to_staging(file)
    end

    # Check that the file exists in the bucket.
    s3 = Aws::S3::Resource.new
    obj = s3.bucket(::Configuration.instance.aws[:bucket]).
        object(@instance.staging_key)
    assert obj.exists?

    # Delete it.
    @instance.delete_from_staging

    # Check that it has been deleted.
    s3 = Aws::S3::Resource.new
    obj = s3.bucket(::Configuration.instance.aws[:bucket]).
        object(@instance.staging_key)
    assert !obj.exists?
  end

  # exists_in_staging

  test "exists_in_staging cannot be set to true when staging_key is blank" do
    @instance.staging_key = nil
    assert_raises ActiveRecord::RecordInvalid do
      @instance.update!(exists_in_staging: true)
    end
  end

  # length

  test "length must be greater than or equal to zero" do
    @instance.length = -1
    assert !@instance.valid?
    @instance.length = 0
    assert @instance.valid?
    @instance.length = 1
    assert @instance.valid?
  end

  # medusa_uuid

  test "medusa_uuid may be nil" do
    @instance.medusa_uuid = nil
    assert @instance.valid?
  end

  test "medusa_uuid can be set to a UUID" do
    @instance.medusa_uuid = SecureRandom.uuid
    assert @instance.valid?
  end

  test "medusa_uuid cannot be set to a nonUUID" do
    @instance.medusa_uuid = "cats-dogs-foxes"
    assert !@instance.valid?
  end

  # staging_key

  test "staging_key may be nil when exists_in_staging is false" do
    @instance.exists_in_staging = false
    @instance.staging_key = nil
    assert @instance.valid?
  end

  test "staging_key must be unique" do
    @instance.update!(staging_key:"cats")
    assert_raises ActiveRecord::RecordNotUnique do
      Bitstream.create!(staging_key: "cats",
                        item: items(:item1))
    end
  end

  # upload_to_medusa()

  test "upload_to_medusa() raises an error if the staging key is blank" do
    @instance.staging_key = nil
    assert_raises do
      @instance.upload_to_medusa
    end
  end

  test "upload_to_medusa() raises an error if a Medusa UUID is already present" do
    @instance.medusa_uuid = SecureRandom.uuid
    assert_raises do
      @instance.upload_to_medusa
    end
  end

  test "upload_to_medusa() sends a message to the queue" do
    @instance.upload_to_medusa
    AmqpHelper::Connector[:ideals].with_parsed_message(MedusaIngest.outgoing_queue) do |message|
      assert_equal "ingest", message['operation']
      assert_equal "bogus", message['staging_key']
      assert_equal "20.500.12644/5000/escher_lego.jpg", message['target_key']
      assert_equal @instance.class.to_s, message['pass_through']['class']
      assert_equal @instance.id.to_s, message['pass_through']['identifier']
    end
  end

  # upload_to_staging()

  test "upload_to_staging() uploads a file to the application bucket" do
    begin
      # Write a file to the bucket.
      fixture = file_fixture("escher_lego.jpg")
      File.open(fixture, "r") do |file|
        @instance = Bitstream.new_in_staging(items(:item1),
                                             File.basename(fixture),
                                             File.size(fixture))
        @instance.upload_to_staging(file)
      end

      # Check that the file exists in the bucket.
      s3 = Aws::S3::Resource.new
      obj = s3.bucket(::Configuration.instance.aws[:bucket]).
          object(@instance.staging_key)
      assert obj.exists?
    ensure
      @instance.delete_from_staging
    end
  end

end
