require 'test_helper'

class BitstreamTest < ActiveSupport::TestCase

  class BundleTest < ActiveSupport::TestCase

    test "all() returns all constant values" do
      assert_equal Bitstream::Bundle.constants.map{ |c| Bitstream::Bundle.const_get(c) }.sort,
                   Bitstream::Bundle.all.sort
    end

    test "for_string() returns a correct value" do
      assert_equal Bitstream::Bundle::LICENSE,
                   Bitstream::Bundle.for_string("LICENSE")
    end

    test "for_string() raises an error for an illegal argument" do
      assert_raises NameError do
        Bitstream::Bundle.for_string("bogus")
      end
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
    setup_s3
    clear_message_queues
    @instance = bitstreams(:item1_in_staging)
    assert @instance.valid?
  end

  teardown do
    teardown_s3
  end

  # create_zip_file()

  test "create_zip_file() creates a zip of bitstreams" do
    bitstreams = [bitstreams(:approved_in_permanent),
                  bitstreams(:license_bundle)]
    dest_key   = "institutions/test/downloads/file.zip"
    Bitstream.create_zip_file(bitstreams: bitstreams, dest_key: dest_key)

    bucket = ::Configuration.instance.storage[:bucket]
    assert S3Client.instance.head_object(bucket: bucket,
                                         key:    dest_key).content_length > 0
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
    item     = items(:uiuc_item1)
    filename = "cats.jpg"
    length   = 3424
    bs       = Bitstream.new_in_staging(item:     item,
                                        filename: filename,
                                        length:   length)
    assert_equal Bitstream.staging_key(institution_key: item.institution.key,
                                       item_id:         item.id,
                                       filename:        filename),
                 bs.staging_key
    assert_equal length, bs.length
    assert_equal filename, bs.original_filename
  end

  # permanent_key()

  test "permanent_key() returns a correct key" do
    expected = ["institutions", "test", "storage", 30, "cats.jpg"].join("/")
    assert_equal expected,
                 Bitstream.permanent_key(institution_key: "test",
                                         item_id:         30,
                                         filename:        "cats.jpg")
  end

  # staging_key()

  test "staging_key() returns a correct key" do
    expected = ["institutions", "test", "uploads", 30, "cats.jpg"].join("/")
    assert_equal expected,
                 Bitstream.staging_key(institution_key: "test",
                                       item_id:         30,
                                       filename:        "cats.jpg")
  end

  # add_download()

  test "add_download() increments the download count" do
    initial_count = @instance.download_count
    @instance.add_download
    @instance.reload
    assert_equal initial_count + 1, @instance.download_count
  end

  test "add_download() creates a MonthlyItemDownloadCount" do
    @instance.add_download
    @instance.add_download
    now = Time.now
    # This is tested more thoroughly in the tests of
    # MonthlyItemDownloadCount.increment().
    assert_equal 2, MonthlyItemDownloadCount.find_by(item_id:  @instance.item_id,
                                                     year:  now.year,
                                                     month: now.month).count
  end

  test "add_download() creates a MonthlyCollectionItemDownloadCount" do
    @instance.add_download
    @instance.add_download
    now = Time.now
    # This is tested more thoroughly in the tests of
    # MonthlyCollectionItemDownloadCount.increment().
    assert_equal 2, MonthlyCollectionItemDownloadCount.find_by(collection_id: @instance.item.primary_collection.id,
                                                               year:          now.year,
                                                               month:         now.month).count
  end

  test "add_download() creates a MonthlyUnitItemDownloadCount" do
    @instance.add_download
    @instance.add_download
    now = Time.now
    # This is tested more thoroughly in the tests of
    # MonthlyUnitItemDownloadCount.increment().
    assert_equal 2, MonthlyUnitItemDownloadCount.find_by(unit_id: @instance.item.primary_collection.primary_unit.id,
                                                         year:    now.year,
                                                         month:   now.month).count
  end

  test "add_download() creates a MonthlyInstitutionItemDownloadCount" do
    @instance.add_download
    @instance.add_download
    now = Time.now
    # This is tested more thoroughly in the tests of
    # MonthlyInstitutionItemDownloadCount.increment().
    assert_equal 2, MonthlyInstitutionItemDownloadCount.find_by(institution_id: @instance.item.primary_collection.primary_unit.institution_id,
                                                                year:           now.year,
                                                                month:          now.month).count
  end

  test "add_download() creates an associated Event" do
    user = users(:example_sysadmin)
    assert_difference "Event.count" do
      @instance.add_download(user: user)
    end
    event = Event.all.order(happened_at: :desc).first
    assert_equal @instance, event.bitstream
    assert_equal "Download", event.description
    assert Time.now - event.happened_at < 10.seconds
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
    group = user_groups(:southwest_unused)
    item = @instance.item
    item.bitstream_authorizations.build(user_group: group)
    item.save!
    assert @instance.authorized_by?(group)
  end

  test "authorized_by?() returns false when the bitstream is not authorized by
  the given user group" do
    group = user_groups(:southwest_unused)
    assert !@instance.authorized_by?(group)
  end

  # bundle

  test "bundle must be a valid bundle" do
    @instance.bundle = 99999
    assert !@instance.valid?
    @instance.bundle = Bitstream::Bundle::CONTENT
    assert @instance.valid?
  end

  # can_read_full_text?()

  test "can_read_full_text?() returns true for a supported format" do
    @instance.original_filename = "doc.pdf"
    assert @instance.can_read_full_text?
  end

  test "can_read_full_text?() returns false for an unsupported format" do
    @instance.original_filename = "image.jpg"
    assert !@instance.can_read_full_text?
  end

  test "create() updates bundle positions in the owning item" do
    item = items(:uiuc_multiple_bitstreams)
    Bitstream.create!(bundle_position:   1,
                      item:              item,
                      original_filename: "cats.jpg")
    # Assert that the positions are sequential and zero-based.
    item.bitstreams.order(:bundle_position).each_with_index do |b, i|
      assert_equal i, b.bundle_position
    end
  end

  # destroy()

  test "destroy() updates bundle positions in the owning item" do
    @instance = bitstreams(:multiple_bitstreams_1)
    item = @instance.item
    @instance.destroy!
    # Assert that the positions are sequential and zero-based.
    item.bitstreams.order(:bundle_position).each_with_index do |b, i|
      assert_equal i, b.bundle_position
    end
  end

  # data()

  test "data() raises an error when an object does not exist in either the
  staging or permanent area" do
    PersistentStore.instance.delete_object(key: @instance.staging_key)
    assert_raises Aws::S3::Errors::NoSuchKey do
      @instance.data
    end
  end

  test "data() returns the data when an object exists in the staging area" do
    File.open(file_fixture("escher_lego.png"), "r") do |file|
      @instance.upload_to_staging(file)
    end
    assert_not_nil @instance.data
  end

  test "data() returns the data when an object exists in the permanent area" do
    File.open(file_fixture("escher_lego.png"), "r") do |file|
      @instance.upload_to_staging(file)
      @instance.move_into_permanent_storage
    end
    assert_not_nil @instance.data
  end

  # delete_derivatives()

  test "delete_derivatives() deletes all derivatives" do
    store = PersistentStore.instance

    # upload the source image to the staging area of the application S3 bucket
    File.open(file_fixture("escher_lego.png"), "r") do |file|
      @instance.upload_to_staging(file)
    end

    # generate a couple of derivatives
    @instance.derivative_url(size: 45)
    @instance.derivative_url(size: 50)

    # check that they exist
    key1 = @instance.send(:derivative_key, region: :full, size: 45, format: :jpg)
    key2 = @instance.send(:derivative_key, region: :full, size: 50, format: :jpg)
    assert store.object_exists?(key: key1)
    assert store.object_exists?(key: key2)

    # delete them
    @instance.delete_derivatives

    # assert that no derivatives exist
    assert !store.object_exists?(key: key1)
    assert !store.object_exists?(key: key2)
  end

  # delete_from_medusa()

  test "delete_from_medusa() does nothing if medusa_uuid is not set" do
    @instance.delete_from_medusa
    queue = @instance.institution.outgoing_message_queue
    AmqpHelper::Connector[:ideals].with_parsed_message(queue) do |message|
      assert_nil message
    end
  end

  test "delete_from_medusa() sends a correct message if medusa_uuid is set" do
    @instance = bitstreams(:item2_in_medusa)
    @instance.delete_from_medusa
    queue = @instance.institution.outgoing_message_queue
    AmqpHelper::Connector[:ideals].with_parsed_message(queue) do |message|
      assert_equal "delete", message['operation']
      assert_equal @instance.medusa_uuid, message['uuid']
      assert_equal @instance.class.to_s, message['pass_through']['class']
      assert_equal @instance.id, message['pass_through']['identifier']
    end
  end

  # delete_from_permanent_storage()

  test "delete_from_permanent_storage() does nothing if the instance has no
  corresponding object" do
    @instance.delete_from_permanent_storage # assert no errors
  end

  test "delete_from_permanent_storage() deletes the corresponding object" do
    store = PersistentStore.instance

    # Write a file to the bucket.
    fixture = file_fixture("escher_lego.png")
    File.open(fixture, "r") do |file|
      @instance = Bitstream.new_in_staging(item:     items(:uiuc_item1),
                                           filename: File.basename(fixture),
                                           length:   File.size(fixture))
      @instance.upload_to_staging(file)
      @instance.move_into_permanent_storage
    end

    permanent_key = @instance.permanent_key

    # Check that the file exists in the bucket.
    assert store.object_exists?(key: permanent_key)
    # Delete it.
    @instance.delete_from_permanent_storage
    # Check that it has been deleted.
    assert !store.object_exists?(key: permanent_key)
  end

  test "delete_from_permanent_storage() updates the instance properties" do
    # Write a file to the bucket.
    fixture = file_fixture("escher_lego.png")
    File.open(fixture, "r") do |file|
      @instance = Bitstream.new_in_staging(item:     items(:uiuc_item1),
                                           filename: File.basename(fixture),
                                           length:   File.size(fixture))
      @instance.upload_to_staging(file)
      @instance.move_into_permanent_storage
    end

    # Check that the file exists in the bucket.
    assert PersistentStore.instance.object_exists?(key: @instance.permanent_key)
    # Delete it.
    @instance.delete_from_permanent_storage
    # Check that the properties have been updated.
    assert_nil @instance.permanent_key
  end

  # delete_from_staging()

  test "delete_from_staging() does nothing if the instance has no corresponding
  object" do
    @instance.delete_from_staging # assert no errors
  end

  test "delete_from_staging() deletes the corresponding object" do
    store = PersistentStore.instance

    # Write a file to the bucket.
    fixture = file_fixture("escher_lego.png")
    File.open(fixture, "r") do |file|
      @instance = Bitstream.new_in_staging(item:     items(:uiuc_item1),
                                           filename: File.basename(fixture),
                                           length:   File.size(fixture))
      @instance.upload_to_staging(file)
    end

    staging_key = @instance.staging_key

    # Check that the file exists in the bucket.
    assert store.object_exists?(key: staging_key)
    # Delete it.
    @instance.delete_from_staging
    # Check that it has been deleted.
    assert !store.object_exists?(key: staging_key)
  end

  test "delete_from_staging() updates the instance properties" do
    # Write a file to the bucket.
    fixture = file_fixture("escher_lego.png")
    File.open(fixture, "r") do |file|
      @instance = Bitstream.new_in_staging(item:     items(:uiuc_item1),
                                           filename: File.basename(fixture),
                                           length:   File.size(fixture))
      @instance.upload_to_staging(file)
    end

    # Check that the file exists in the bucket.
    assert PersistentStore.instance.object_exists?(key: @instance.staging_key)
    # Delete it.
    @instance.delete_from_staging
    # Check that the properties have been updated.
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
    File.open(file_fixture("escher_lego.png"), "r") do |file|
      @instance.upload_to_staging(file)
    end

    url = @instance.derivative_url(size: 45)

    client   = HTTPClient.new
    response = client.get(url)
    assert_equal 200, response.code
    assert response.headers['Content-Length'].to_i > 1000
  end

  # destroy()

  test "destroy() deletes the corresponding file from the staging area of the
  application bucket" do
    @instance = bitstreams(:submitted_in_staging)
    store     = PersistentStore.instance
    key       = Bitstream.staging_key(institution_key: @instance.institution.key,
                                      item_id:         @instance.item_id,
                                      filename:        @instance.original_filename)
    assert store.object_exists?(key: key)
    @instance.destroy!
    assert !store.object_exists?(key: key)
  end

  test "destroy() deletes the corresponding file from the permanent area of the
  application bucket" do
    @instance = bitstreams(:approved_in_permanent)
    store     = PersistentStore.instance
    key       = Bitstream.permanent_key(institution_key: @instance.institution.key,
                                        item_id:         @instance.item_id,
                                        filename:        @instance.original_filename)
    assert store.object_exists?(key: key)
    @instance.destroy!
    assert !store.object_exists?(key: key)
  end

  test "destroy() deletes corresponding derivatives" do
    @instance  = bitstreams(:submitted_in_staging)
    store      = PersistentStore.instance
    key_prefix = @instance.send(:derivative_key_prefix)
    @instance.derivative_url(size: 256) # generate a derivative

    assert store.objects(key_prefix: key_prefix).count > 0

    @instance.destroy!
    assert_equal 0, store.objects(key_prefix: key_prefix).count
  end

  test "destroy() does not send a delete message to Medusa if medusa_uuid is
  not set" do
    @instance = bitstreams(:submitted_in_staging)
    @instance.destroy!
    queue = @instance.institution.outgoing_message_queue
    AmqpHelper::Connector[:ideals].with_parsed_message(queue) do |message|
      assert_nil message
    end
  end

  test "destroy() sends a delete message to Medusa if medusa_uuid is set" do
    Message.destroy_all
    @instance = bitstreams(:item2_in_medusa)
    @instance.destroy!
    queue = @instance.institution.outgoing_message_queue
    AmqpHelper::Connector[:ideals].with_parsed_message(queue) do |message|
      assert_not_nil message
    end
  end

  # download_count()

  test "download_count() returns a correct value" do
    @instance.events.build(event_type: Event::Type::DOWNLOAD).save!
    assert_equal 1, @instance.download_count
  end

  # download_to_temp_file()

  test "download_to_temp_file() works" do
    file = @instance.download_to_temp_file
    assert File.exist?(file.path)
    File.delete(file)
  end

  # effective_key()

  test "effective_key() returns the permanent key if both it and the staging
  key are set" do
    @instance.permanent_key = "cats"
    @instance.staging_key   = "dogs"
    assert_equal "cats", @instance.effective_key
  end

  test "effective_key() returns the permanent key if the staging key is not
  set" do
    @instance.permanent_key = "cats"
    @instance.staging_key   = nil
    assert_equal "cats", @instance.effective_key
  end

  test "effective_key() returns the staging key if the permanent key is not
  set" do
    @instance.permanent_key = nil
    @instance.staging_key   = "cats"
    assert_equal "cats", @instance.effective_key
  end

  test "effective_key() returns nil if neither the permanent key nor staging
  key is set" do
    @instance.permanent_key = nil
    @instance.staging_key   = nil
    assert_nil @instance.effective_key
  end

  # format()

  test "format() returns the correct format" do
    assert_equal "image/png", @instance.format.media_types[0]
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

  # ingest_into_medusa()

  test "ingest_into_medusa() raises an error if the ID is blank" do
    @instance = Bitstream.new
    @instance.item = items(:uiuc_item1)
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

  test "ingest_into_medusa() raises an error if preservation is not active for
  the owning institution" do
    @instance = bitstreams(:awaiting_ingest_into_medusa)
    @instance.institution.outgoing_message_queue = nil
    assert_raises ArgumentError do
      @instance.ingest_into_medusa
    end
  end

  test "ingest_into_medusa() raises an error if the owning item's handle does
  not have a suffix" do
    @instance = bitstreams(:approved_in_permanent)
    @instance.item.handle.suffix = nil
    assert_raises AlreadyExistsError do
      @instance.ingest_into_medusa
    end
  end

  test "ingest_into_medusa() raises an error if the owning item does not have a
  handle" do
    @instance.item.handle.destroy!
    @instance.item.handle = nil
    assert_raises ArgumentError do
      @instance.ingest_into_medusa
    end
  end

  test "ingest_into_medusa() raises an error if the instance has already been
  submitted for ingest and the force argument is false" do
    @instance = bitstreams(:approved_in_permanent)
    assert_raises AlreadyExistsError do
      @instance.ingest_into_medusa
    end
  end

  test "ingest_into_medusa() does not raise an error if the instance has
  already been submitted for ingest but the force argument is true" do
    @instance.permanent_key        = "cats"
    @instance.submitted_for_ingest = true
    @instance.ingest_into_medusa(force: true)
  end

  test "ingest_into_medusa() raises an error if a Medusa UUID is already present
  and the force argument is false" do
    @instance.permanent_key = "cats"
    @instance.medusa_uuid   = SecureRandom.uuid
    assert_raises AlreadyExistsError do
      @instance.ingest_into_medusa
    end
  end

  test "ingest_into_medusa() does not raise an error if a Medusa UUID is
  already present but the force argument is true" do
    @instance.permanent_key = "cats"
    @instance.medusa_uuid   = SecureRandom.uuid
    @instance.ingest_into_medusa(force: true)
  end

  test "ingest_into_medusa() sends a message to the queue" do
    @instance = bitstreams(:awaiting_ingest_into_medusa)
    @instance.ingest_into_medusa
    queue     = @instance.institution.outgoing_message_queue
    AmqpHelper::Connector[:ideals].with_parsed_message(queue) do |message|
      config = ::Configuration.instance
      assert_equal "ingest", message['operation']
      assert_equal "#{@instance.item.id}/escher_lego.png", message['staging_key']
      assert_equal "#{config.handles[:prefix]}/#{@instance.item.handle.suffix}/escher_lego.png",
                   message['target_key']
      assert_equal @instance.class.to_s, message['pass_through']['class']
      assert_equal @instance.id, message['pass_through']['identifier']
    end
  end

  # institution()

  test "institution() returns the owning institution" do
    assert_same @instance.item.institution, @instance.institution
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

  # move_into_permanent_storage()

  test "move_into_permanent_storage() raises an error if no object exists in
  staging" do
    @instance = Bitstream.new_in_staging(item:     items(:uiuc_item1),
                                         filename: "file.jpg",
                                         length:   1234)
    assert_raises do
      @instance.move_into_permanent_storage
    end
  end

  test "move_into_permanent_storage() updates instance properties" do
    begin
      fixture = file_fixture("escher_lego.png")
      File.open(fixture, "r") do |file|
        @instance = Bitstream.new_in_staging(item:     items(:uiuc_item1),
                                             filename: File.basename(fixture),
                                             length:   File.size(fixture))
        @instance.upload_to_staging(file)
        @instance.move_into_permanent_storage
      end

      assert_nil @instance.staging_key
      assert_equal Bitstream.permanent_key(institution_key: @instance.institution.key,
                                           item_id:         @instance.item_id,
                                           filename:        @instance.original_filename),
                   @instance.permanent_key
    ensure
      @instance.delete_from_staging
      @instance.delete_from_permanent_storage
    end
  end

  test "move_into_permanent_storage() moves a staging object into permanent
  storage" do
    begin
      fixture = file_fixture("escher_lego.png")
      File.open(fixture, "r") do |file|
        @instance = Bitstream.new_in_staging(item:     items(:uiuc_item1),
                                             filename: File.basename(fixture),
                                             length:   File.size(fixture))
        @instance.upload_to_staging(file)
        @instance.move_into_permanent_storage
      end

      # Check that the file exists in the bucket.
      assert PersistentStore.instance.object_exists?(key: @instance.permanent_key)
    ensure
      @instance.delete_from_staging
      @instance.delete_from_permanent_storage
    end
  end

  # presigned_url()

  test "presigned_url() returns a presigned URL for an object in staging" do
    @instance.staging_key   = "key"
    @instance.permanent_key = nil
    assert_not_nil @instance.presigned_url
  end

  test "presigned_url() returns a presigned URL for an object in permanent
  storage" do
    @instance.staging_key   = nil
    @instance.permanent_key = "key"
    assert_not_nil @instance.presigned_url
  end

  test "presigned_url() returns a presigned URL with a correct
  response-content-type for an instance with a known format" do
    @instance.original_filename = "image.jpg"
    assert @instance.presigned_url.include?("response-content-type=image%2Fjpeg")
  end

  test "presigned_url() returns a presigned URL with a correct
  response-content-type for an instance with an unknown format" do
    @instance.original_filename = "image.whatsthis"
    assert @instance.presigned_url.include?("response-content-type=application%2Foctet-stream")
  end

  test "presigned_url() raises an IOError if the instance has no corresponding
  object" do
    @instance.staging_key   = nil
    @instance.permanent_key = nil
    assert_raises IOError do
      @instance.presigned_url
    end
  end

  # public_url()

  test "public_url() returns a URL for an object in staging" do
    @instance.staging_key   = "key"
    @instance.permanent_key = nil
    assert_not_nil @instance.public_url
  end

  test "public_url() returns a URL for an object in permanent storage" do
    @instance.staging_key   = nil
    @instance.permanent_key = "key"
    assert_not_nil @instance.public_url
  end

  test "public_url() raises an IOError if the instance has no corresponding
  object" do
    @instance.staging_key   = nil
    @instance.permanent_key = nil
    assert_raises IOError do
      @instance.public_url
    end
  end

  # read_full_text()

  test "read_full_text() works when full_text_checked_at is not set and force
  argument is false" do
    @instance = bitstreams(:approved_in_permanent)
    @instance.update!(full_text_checked_at: nil,
                      full_text:            nil)
    @instance.read_full_text(force: false)

    assert_not_nil @instance.full_text_checked_at
    assert_not_nil @instance.full_text
  end

  test "read_full_text() works when full_text_checked_at is not set and force
  argument is true" do
    @instance = bitstreams(:approved_in_permanent)
    @instance.update!(full_text_checked_at: nil,
                      full_text:            nil)
    @instance.read_full_text(force: true)

    assert_not_nil @instance.full_text_checked_at
    assert_not_nil @instance.full_text
  end

  test "read_full_text() does nothing when full_text_checked_at is set and
  force argument is false" do
    @instance = bitstreams(:approved_in_permanent)
    checked_at = Time.now.utc
    text       = "cats"
    @instance.update!(full_text_checked_at: checked_at)
    @instance.create_full_text!(text: text)
    @instance.read_full_text(force: false)

    assert_equal checked_at.to_i, @instance.full_text_checked_at.to_i
    assert_equal text, @instance.full_text.text
  end

  test "read_full_text() works when full_text_checked_at is set and
  force argument is true" do
    @instance               = bitstreams(:approved_in_permanent)
    @instance.permanent_key = Bitstream.permanent_key(institution_key: @instance.institution.key,
                                                      item_id:         @instance.item_id,
                                                      filename:        @instance.original_filename)
    checked_at = Time.now
    text       = "cats"
    @instance.update!(full_text_checked_at: checked_at)
    @instance.create_full_text!(text: text)
    @instance.read_full_text(force: true)

    assert checked_at < @instance.full_text_checked_at
    assert_not_equal text, @instance.full_text
  end

  test "read_full_text() does nothing with an incompatible format" do
    @instance.update!(full_text_checked_at: nil,
                      full_text:            nil)
    @instance.read_full_text(force: true)

    assert_not_nil @instance.full_text_checked_at
    assert_nil @instance.full_text
  end

  # read_full_text_async()

  test "read_full_text_async() works when full_text_checked_at is not set" do
    # This won't work because ActiveJob in the test environment uses the
    # test backend, which is not asynchronous
    skip
    @instance = bitstreams(:approved_in_permanent)
    @instance.update!(full_text_checked_at: nil,
                      full_text:            nil)
    @instance.read_full_text_async

    sleep 2

    @instance.reload
    assert_not_nil @instance.full_text_checked_at
    assert_not_nil @instance.full_text
  end

  test "read_full_text_async() does nothing when full_text_checked_at is set" do
    checked_at = Time.now.utc
    text       = "cats"
    @instance.update!(full_text_checked_at: checked_at,
                      full_text:            FullText.new(text: text))
    @instance.read_full_text_async

    sleep 2

    @instance.reload
    assert_equal checked_at.to_i, @instance.full_text_checked_at.to_i
    assert_equal text, @instance.full_text.text
  end

  # role

  test "role must be a valid role ID" do
    @instance.role = 99999
    assert !@instance.valid?
    @instance.role = Role::COLLECTION_MANAGER
    assert @instance.valid?
  end

  # save()

  test "save() sets all other bitstreams attached to the same item to not
  primary" do
    item = items(:uiuc_approved)
    b1   = item.bitstreams.build(primary: true)
    b2   = item.bitstreams.build(primary: false)
    item.save!
    b2.update!(primary: true)
    b1.reload
    assert !b1.primary
  end

  test "save() does not send an ingest message to Medusa if the permanent key
  is not set" do
    @instance = bitstreams(:submitted_in_staging)
    @instance.save!
    queue     = @instance.institution.outgoing_message_queue
    AmqpHelper::Connector[:ideals].with_parsed_message(queue) do |message|
      assert_nil message
    end
  end

  test "save() does not send an ingest message to Medusa if preservation is not
  active on the owning institution" do
    @instance = bitstreams(:submitted_in_staging)
    @instance.institution.medusa_file_group_id = nil
    @instance.save!
    queue     = @instance.institution.outgoing_message_queue
    AmqpHelper::Connector[:ideals].with_parsed_message(queue) do |message|
      assert_nil message
    end
  end

  test "save() does not send an ingest message to Medusa if the permanent key
  has not changed" do
    @instance = bitstreams(:awaiting_ingest_into_medusa)
    @instance.save!
    queue = @instance.institution.outgoing_message_queue
    AmqpHelper::Connector[:ideals].with_parsed_message(queue) do |message|
      assert_nil message
    end
  end

  test "save() sends an ingest message to Medusa if the permanent key has
  changed" do
    @instance = bitstreams(:submitted_in_staging)
    @instance.item.assign_handle
    @instance.update!(permanent_key: ["institutions",
                                      @instance.institution.key,
                                      "storage",
                                      "new_key"].join("/"))
    queue = @instance.institution.outgoing_message_queue
    AmqpHelper::Connector[:ideals].with_parsed_message(queue) do |message|
      assert_not_nil message
    end
  end

  test "save() reads full text asynchronously when full_text_checked_at is not
  set and an effective key exists" do
    # This won't work because ActiveJob in the test environment uses the
    # test backend, which is not asynchronous
    skip
    @instance = bitstreams(:approved_in_permanent)
    @instance.update!(full_text_checked_at: nil,
                      full_text:            nil)
    sleep 2

    @instance.reload
    assert_not_nil @instance.full_text_checked_at
    assert_equal "This is a PDF", @instance.full_text.text
  end

  test "save() does not read full text when the bundle is not CONTENT" do
    @instance = bitstreams(:approved_in_permanent)
    @instance.update!(bundle:               Bitstream::Bundle::LICENSE,
                      full_text_checked_at: nil,
                      full_text:            nil)
    sleep 2

    @instance.reload
    assert_nil @instance.full_text_checked_at
    assert_nil @instance.full_text
  end

  test "save() does not read full text when full_text_is_checked_at is set" do
    @instance = bitstreams(:approved_in_permanent)
    time      = Time.now.utc
    @instance.update!(full_text_checked_at: time,
                      full_text:            FullText.new(text: "cats"))
    sleep 2

    @instance.reload
    assert_equal time.to_i, @instance.full_text_checked_at.to_i
    assert_equal "cats", @instance.full_text.text
  end

  test "save() does not read full text when an effective key does not exist" do
    @instance = bitstreams(:approved_in_permanent)
    @instance.update!(full_text_checked_at: nil,
                      full_text:            nil,
                      staging_key:          nil,
                      permanent_key:        nil)
    sleep 2

    @instance.reload
    assert_nil @instance.full_text_checked_at
    assert_nil @instance.full_text
  end

  # staging_key

  test "staging_key must be unique" do
    @instance.update!(staging_key:"cats")
    assert_raises ActiveRecord::RecordNotUnique do
      Bitstream.create!(staging_key: "cats",
                        item:        items(:uiuc_item1))
    end
  end

  # update()

  test "update() update bundle positions in the owning item when increasing a
  bundle position" do
    @instance = bitstreams(:multiple_bitstreams_1)
    assert_equal 0, @instance.bundle_position
    @instance.update!(bundle_position: 2)
    # Assert that the positions are sequential and zero-based.
    @instance.item.bitstreams.order(:bundle_position).each_with_index do |b, i|
      assert_equal i, b.bundle_position
    end
  end

  test "update() updates bundle positions in the owning item when decreasing a
  bundle position" do
    @instance = bitstreams(:multiple_bitstreams_1)
    @instance = @instance.item.bitstreams.where(bundle_position: 2).first
    @instance.update!(bundle_position: 0)
    # Assert that the positions are sequential and zero-based.
    @instance.item.bitstreams.order(:bundle_position).each_with_index do |b, i|
      assert_equal i, b.bundle_position
    end
  end

  # upload_to_permanent()

  test "upload_to_permanent() uploads a file to the application bucket" do
    begin
      fixture = file_fixture("escher_lego.png")
      key     = %w[institutions uiuc storage file].join("/")
      @instance.update!(permanent_key: key)
      @instance.upload_to_permanent(fixture)

      # Check that the file exists in the bucket.
      assert PersistentStore.instance.object_exists?(key: @instance.permanent_key)
    ensure
      @instance.delete_from_permanent_storage
    end
  end

  # upload_to_staging()

  test "upload_to_staging() uploads a file to the application bucket" do
    begin
      # Write a file to the bucket.
      fixture = file_fixture("escher_lego.png")
      File.open(fixture, "r") do |file|
        @instance = Bitstream.new_in_staging(item:     items(:uiuc_item1),
                                             filename: File.basename(fixture),
                                             length:   File.size(fixture))
        @instance.upload_to_staging(file)
      end

      # Check that the file exists in the bucket.
      assert PersistentStore.instance.object_exists?(key: @instance.staging_key)
    ensure
      @instance.delete_from_staging
    end
  end

end
