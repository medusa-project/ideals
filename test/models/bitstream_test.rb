require 'test_helper'

class BitstreamTest < ActiveSupport::TestCase

  setup do
    @instance = bitstreams(:item1_jpg)
    assert @instance.valid?
    create_bucket
  end

  def create_bucket
    client   = Aws::S3::Client.new
    resource = Aws::S3::Resource.new
    bucket   = ::Configuration.instance.aws[:bucket]
    unless resource.bucket(bucket).exists?
      client.create_bucket(bucket: bucket)
    end
  end

  # new_in_staging()

  test "new_in_staging() returns a correct instance" do
    item     = items(:item1)
    filename = "cats.jpg"
    length   = 3424
    bs       = Bitstream.new_in_staging(item, filename, length)
    assert_equal Bitstream.staging_key(item.id, filename), bs.key
    assert_equal length, bs.length
    assert_equal filename, bs.original_filename
    assert_nil bs.media_type
  end

  # staging_key()

  test "staging_key() returns a correct key" do
    assert_equal "#{Bitstream::STAGING_KEY_PREFIX}/30/cats.jpg",
                 Bitstream.staging_key(30, "cats.jpg")
  end

  # delete_object()

  test "delete_object() deletes the corresponding object" do
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
        object(@instance.key)
    assert obj.exists?

    # Delete it.
    @instance.delete_object

    # Check that it has been deleted.
    s3 = Aws::S3::Resource.new
    obj = s3.bucket(::Configuration.instance.aws[:bucket]).
        object(@instance.key)
    assert !obj.exists?
  end

  test "delete_object() does nothing if the instance has no corresponding object" do
    @instance.delete_object # assert no errors
  end

  # key

  test "key must be present" do
    @instance.key = nil
    assert !@instance.valid?
    @instance.key = ""
    assert !@instance.valid?
  end

  test "key must be unique" do
    @instance.update!(key:"cats")
    assert_raises ActiveRecord::RecordInvalid do
      Bitstream.create!(key: "cats", item: items(:item1))
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
          object(@instance.key)
      assert obj.exists?
    ensure
      @instance.delete_object
    end
  end

end
