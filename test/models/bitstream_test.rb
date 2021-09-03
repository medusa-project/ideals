require 'test_helper'

class BitstreamTest < ActiveSupport::TestCase

  class BundleTest < ActiveSupport::TestCase

    test "all() returns all constant values" do
      assert_equal Bitstream::Bundle.constants.map{ |c| Bitstream::Bundle.const_get(c) }.sort,
                   Bitstream::Bundle.all.sort
    end

    test "label() returns a correct label" do
      assert_equal "Branded Preview",
                   Bitstream::Bundle.label(Bitstream::Bundle::BRANDED_PREVIEW)
    end

    test "label() raises an error for an illegal argument" do
      assert_raises ArgumentError do
        Bitstream::Bundle.label(99999)
      end
    end

  end

  setup do
    @instance = bitstreams(:item1_in_staging)
    assert @instance.valid?
    Bitstream.create_bucket
  end

  teardown do
    AmqpHelper::Connector[:ideals].clear_queues(Message.outgoing_queue)
    S3Client.instance.delete_objects(bucket: ::Configuration.instance.aws[:bucket],
                                     key_prefix: "/")
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
    bs       = Bitstream.new_in_staging(item:     item,
                                        filename: filename,
                                        length:   length)
    assert_equal Bitstream.staging_key(item.id, filename), bs.staging_key
    assert_equal length, bs.length
    assert_equal filename, bs.original_filename
    assert_equal "image/jpeg", bs.media_type
  end

  # staging_key()

  test "staging_key() returns a correct key" do
    assert_equal "#{Bitstream::STAGING_KEY_PREFIX}/30/cats.jpg",
                 Bitstream.staging_key(30, "cats.jpg")
  end

  # add_download()

  test "add_download() increments the download count" do
    initial_count = @instance.download_count
    @instance.add_download
    @instance.reload
    assert_equal initial_count + 1, @instance.download_count
  end

  test "add_download() creates an associated Event" do
    user = users(:local_sysadmin)
    assert_difference "Event.count" do
      @instance.add_download(user: user)
    end
    event = Event.all.order(happened_at: :desc).first
    assert_equal @instance, event.bitstream
    assert_equal "Download", event.description
    assert_equal user, event.user
  end

  test "add_download() without a user argument creates a correct Event" do
    assert_difference "Event.count" do
      @instance.add_download
    end
  end

  # authorized_by?()

  test "authorized_by?() returns true when the bitstream is authorized by the
  given user group" do
    group = user_groups(:unused)
    item = @instance.item
    item.bitstream_authorizations.build(user_group: group)
    item.save!
    assert @instance.authorized_by?(group)
  end

  test "authorized_by?() returns false when the bitstream is not authorized by
  the given user group" do
    group = user_groups(:unused)
    assert !@instance.authorized_by?(group)
  end

  # bundle

  test "bundle must be a valid bundle" do
    @instance.bundle = 99999
    assert !@instance.valid?
    @instance.bundle = Bitstream::Bundle::CONTENT
    assert @instance.valid?
  end

  # data()

  test "data() raises an error when an object does not exist in either the
  staging or production bucket" do
    assert_raises Aws::S3::Errors::NoSuchKey do
      @instance.data
    end
  end

  test "data() returns the data when an object exists in the staging bucket" do
    File.open(File.join(Rails.root, "test", "fixtures", "files", "escher_lego.jpg"), "r") do |file|
      @instance.upload_to_staging(file)
    end
    assert_not_nil @instance.data
  end

  # delete_derivatives()

  test "delete_derivatives() deletes all derivatives" do
    client = S3Client.instance
    bucket = ::Configuration.instance.aws[:bucket]

    # upload the source image to the staging area of the application S3 bucket
    File.open(File.join(Rails.root, "test", "fixtures", "files", "escher_lego.jpg"), "r") do |file|
      @instance.upload_to_staging(file)
    end

    # generate a couple of derivatives
    @instance.derivative_url(size: 45)
    @instance.derivative_url(size: 50)

    # check that they exist
    key1 = @instance.send(:derivative_key, region: :full, size: 45, format: :jpg)
    key2 = @instance.send(:derivative_key, region: :full, size: 50, format: :jpg)
    assert client.object_exists?(bucket: bucket, key: key1)
    assert client.object_exists?(bucket: bucket, key: key2)

    # delete them
    @instance.delete_derivatives

    # assert that no derivatives exist
    assert !client.object_exists?(bucket: bucket, key: key1)
    assert !client.object_exists?(bucket: bucket, key: key2)
  end

  # delete_from_medusa()

  test "delete_from_medusa() does nothing if medusa_uuid is not set" do
    @instance.delete_from_medusa
    AmqpHelper::Connector[:ideals].with_parsed_message(Message.outgoing_queue) do |message|
      assert_nil message
    end
  end

  test "delete_from_medusa() sends a correct message if medusa_uuid is set" do
    @instance = bitstreams(:item2_in_medusa)
    @instance.delete_from_medusa
    AmqpHelper::Connector[:ideals].with_parsed_message(Message.outgoing_queue) do |message|
      puts message
      assert_equal "delete", message['operation']
      assert_equal @instance.medusa_uuid, message['uuid']
      assert_equal @instance.class.to_s, message['pass_through']['class']
      assert_equal @instance.id, message['pass_through']['identifier']
    end
  end

  # delete_from_staging()

  test "delete_from_staging() does nothing if the instance has no corresponding object" do
    @instance.delete_from_staging # assert no errors
  end

  test "delete_from_staging() deletes the corresponding object" do
    config = ::Configuration.instance

    # Write a file to the bucket.
    fixture = file_fixture("escher_lego.jpg")
    File.open(fixture, "r") do |file|
      @instance = Bitstream.new_in_staging(item:     items(:item1),
                                           filename: File.basename(fixture),
                                           length:   File.size(fixture))
      @instance.upload_to_staging(file)
    end

    staging_key = @instance.staging_key

    # Check that the file exists in the bucket.
    assert S3Client.instance.object_exists?(bucket: config.aws[:bucket],
                                            key:    staging_key)

    # Delete it.
    @instance.delete_from_staging

    # Check that it has been deleted.
    assert !S3Client.instance.object_exists?(bucket: config.aws[:bucket],
                                             key:    staging_key)
  end

  test "delete_from_staging() updates the instance properties" do
    # Write a file to the bucket.
    fixture = file_fixture("escher_lego.jpg")
    File.open(fixture, "r") do |file|
      @instance = Bitstream.new_in_staging(item:     items(:item1),
                                           filename: File.basename(fixture),
                                           length:   File.size(fixture))
      @instance.upload_to_staging(file)
    end

    # Check that the file exists in the bucket.
    config = ::Configuration.instance
    assert S3Client.instance.object_exists?(bucket: config.aws[:bucket],
                                            key:    @instance.staging_key)

    # Delete it.
    @instance.delete_from_staging

    # Check that the properties have been updated.
    assert !@instance.exists_in_staging
    assert_nil @instance.staging_key
  end

  # derivative_url()

  test "derivative_url() with an unsupported format raises an error" do
    @instance.original_filename = "cats.bogus"
    assert_raises do
      @instance.derivative_url(size: 45)
    end
  end

  test "derivative_url() generates a correct URL" do
    # upload the source image to the staging area of the application S3 bucket
    File.open(File.join(Rails.root, "test", "fixtures", "files", "escher_lego.jpg"), "r") do |file|
      @instance.upload_to_staging(file)
    end

    url = @instance.derivative_url(size: 45)

    client   = HTTPClient.new
    response = client.get(url)
    assert_equal 200, response.code
    assert response.headers['Content-Length'].to_i > 10000
  end

  # download_count()

  test "download_count() returns a correct value" do
    @instance.events.build(event_type: Event::Type::DOWNLOAD).save!
    assert_equal 1, @instance.download_count
  end

  # dspace_relative_path()

  test "dspace_relative_path() returns nil when dspace_id is not set" do
    assert_nil @instance.dspace_relative_path
  end

  test "dspace_relative_path() returns the correct path" do
    @instance.dspace_id = "125415979481218159291827549801925969929"
    assert_equal "/12/54/15/125415979481218159291827549801925969929",
                 @instance.dspace_relative_path
  end

  # exists_in_staging

  test "exists_in_staging cannot be set to true when staging_key is blank" do
    @instance.staging_key = nil
    assert_raises ActiveRecord::RecordInvalid do
      @instance.update!(exists_in_staging: true)
    end
  end

  # format()

  test "format() returns the correct format" do
    assert_equal "image/jpeg", @instance.format.media_types[0]
  end

  test "format() returns nil for an unknown format" do
    @instance.original_filename = "bogus"
    assert_nil @instance.format
  end

  # has_representative_image?()

  test "has_representative_image?() returns true for an instance that is in a
   supported format" do
    @instance.original_filename = "file.jpg"
    assert @instance.has_representative_image?
  end

  test "has_representative_image?() returns false for an instance that is not
  in a supported format" do
    @instance.original_filename = "file.txt"
    assert !@instance.has_representative_image?
  end

  test "has_representative_image?() returns false for an instance that is in an
  unrecognized format" do
    @instance.original_filename = "file.bogus"
    assert !@instance.has_representative_image?
  end

  # infer_media_type()

  test "infer_media_type() infers a correct media type" do
    @instance.media_type = nil
    @instance.infer_media_type
    assert_equal "image/jpeg", @instance.media_type
  end

  # ingest_into_medusa()

  test "ingest_into_medusa() raises an error if the ID is blank" do
    @instance = Bitstream.new
    @instance.item = items(:item1)
    assert_raises ArgumentError do
      @instance.ingest_into_medusa
    end
  end

  test "ingest_into_medusa() raises an error if the staging key is blank" do
    @instance.staging_key = nil
    assert_raises ArgumentError do
      @instance.ingest_into_medusa
    end
  end

  test "ingest_into_medusa() raises an error if the owning item's handle does not have a suffix" do
    @instance.item.handle.suffix = nil
    assert_raises ArgumentError do
      @instance.ingest_into_medusa
    end
  end

  test "ingest_into_medusa() raises an error if the owning item does not have a handle" do
    @instance.item.handle.destroy!
    @instance.item.handle = nil
    assert_raises ArgumentError do
      @instance.ingest_into_medusa
    end
  end

  test "ingest_into_medusa() raises an error if the instance has already been
  submitted for ingest" do
    @instance.submitted_for_ingest = true
    assert_raises AlreadyExistsError do
      @instance.ingest_into_medusa
    end
  end

  test "ingest_into_medusa() raises an error if a Medusa UUID is already present" do
    @instance.medusa_uuid = SecureRandom.uuid
    assert_raises AlreadyExistsError do
      @instance.ingest_into_medusa
    end
  end

  test "ingest_into_medusa() sends a message to the queue" do
    @instance.ingest_into_medusa
    AmqpHelper::Connector[:ideals].with_parsed_message(Message.outgoing_queue) do |message|
      config = ::Configuration.instance
      assert_equal "ingest", message['operation']
      assert_equal "969722354/escher_lego.jpg", message['staging_key']
      assert_equal "#{config.handles[:prefix]}/5000/escher_lego.jpg",
                   message['target_key']
      assert_equal @instance.class.to_s, message['pass_through']['class']
      assert_equal @instance.id, message['pass_through']['identifier']
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

  # medusa_url()

  test "medusa_url() returns a correct URL when medusa_uuid is set" do
    @instance.medusa_uuid = "cats"
    expected = [::Configuration.instance.medusa[:base_url],
                "uuids",
                @instance.medusa_uuid].join("/")
    assert_equal expected, @instance.medusa_url
  end

  test "medusa_url() returns nil when medusa_uuid is not set" do
    @instance.medusa_uuid = nil
    assert_nil @instance.medusa_url
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

  # presigned_url()

  test "presigned_url() returns a presigned URL for an object in staging" do
    @instance.exists_in_staging = true
    @instance.staging_key       = "key"
    @instance.medusa_key        = nil
    assert_not_nil @instance.presigned_url
  end

  test "presigned_url() returns a presigned URL for an object in production" do
    @instance.exists_in_staging = false
    @instance.staging_key       = nil
    @instance.medusa_key        = "key"
    assert_not_nil @instance.presigned_url
  end

  test "presigned_url() raises an IOError if the instance has no corresponding
  object" do
    @instance.exists_in_staging = false
    @instance.staging_key       = nil
    @instance.medusa_key        = nil
    assert_raises IOError do
      @instance.presigned_url
    end
  end

  # role

  test "role must be a valid role ID" do
    @instance.role = 99999
    assert !@instance.valid?
    @instance.role = Role::COLLECTION_MANAGER
    assert @instance.valid?
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

  # upload_to_staging()

  test "upload_to_staging() uploads a file to the application bucket" do
    begin
      # Write a file to the bucket.
      fixture = file_fixture("escher_lego.jpg")
      File.open(fixture, "r") do |file|
        @instance = Bitstream.new_in_staging(item:     items(:item1),
                                             filename: File.basename(fixture),
                                             length:   File.size(fixture))
        @instance.upload_to_staging(file)
      end

      # Check that the file exists in the bucket.
      config = ::Configuration.instance
      assert S3Client.instance.object_exists?(bucket: config.aws[:bucket],
                                              key:    @instance.staging_key)
    ensure
      @instance.delete_from_staging
    end
  end

end
