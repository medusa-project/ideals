require 'test_helper'

class S3ClientTest < ActiveSupport::TestCase

  setup do
    bucket = ::Configuration.instance.aws[:bucket]
    client = S3Client.instance
    unless client.bucket_exists?(bucket)
      client.create_bucket(bucket: bucket)
    end
  end

  teardown do
    bucket = ::Configuration.instance.aws[:bucket]
    S3Client.instance.delete_objects(bucket: bucket, key_prefix: "/")
  end

  # bucket_exists?()

  test "bucket_exists?() returns true when the bucket exists" do
    bucket = ::Configuration.instance.aws[:bucket]
    assert S3Client.instance.bucket_exists?(bucket)
  end

  test "bucket_exists?() returns false when the bucket does not exist" do
    assert !S3Client.instance.bucket_exists?("bogus")
  end

  # delete_objects()

  test "delete_objects() deletes all intended objects" do
    bucket = ::Configuration.instance.aws[:bucket]
    client = S3Client.instance
    file   = File.join(Rails.root, "test", "fixtures", "files", "escher_lego.jpg")
    client.put_object(bucket: bucket,
                      key:   "cats/siamese",
                      body:   file)
    client.put_object(bucket: bucket,
                      key:   "cats/mainecoon",
                      body:   file)
    client.put_object(bucket: bucket,
                      key:   "dogs",
                      body:   file)

    client.delete_objects(bucket: bucket, key_prefix: "cats")

    assert !client.object_exists?(bucket: bucket, key: "cats/siamese")
    assert !client.object_exists?(bucket: bucket, key: "cats/mainecoon")
    assert client.object_exists?(bucket: bucket, key: "dogs")
  end

  # num_objects()

  test "num_objects() returns a correct count" do
    bucket = ::Configuration.instance.aws[:bucket]
    client = S3Client.instance
    file   = File.join(Rails.root, "test", "fixtures", "files", "escher_lego.jpg")
    client.put_object(bucket: bucket,
                      key:   "cats/siamese",
                      body:   file)
    client.put_object(bucket: bucket,
                      key:   "cats/mainecoon",
                      body:   file)
    assert_equal 2, client.num_objects(bucket: bucket, key_prefix: "cats")
  end

  # object_exists?()

  test "object_exists?() returns true when the object exists" do
    config = ::Configuration.instance
    bucket = config.aws[:bucket]
    key    = "test-#{SecureRandom.hex}"
    client = S3Client.instance
    begin
      client.put_object(bucket: bucket,
                        key:    key,
                        body:   File.join(Rails.root, "test", "fixtures", "files", "escher_lego.jpg"))
      assert client.object_exists?(bucket: bucket, key: key)
    ensure
      client.delete_object(bucket: bucket, key: key)
    end
  end

  test "object_exists?() returns false when the bucket does not exist" do
    assert !S3Client.instance.object_exists?(bucket: "bogus", key: "bogus")
  end

  test "object_exists?() returns false when the object does not exist" do
    bucket = ::Configuration.instance.aws[:bucket]
    assert !S3Client.instance.object_exists?(bucket: bucket, key: "bogus")
  end

  # objects()

  test "objects() returns a correct value" do
    bucket = ::Configuration.instance.aws[:bucket]
    client = S3Client.instance
    file   = File.join(Rails.root, "test", "fixtures", "files", "escher_lego.jpg")
    client.put_object(bucket: bucket,
                      key:   "cats/siamese",
                      body:   file)
    client.put_object(bucket: bucket,
                      key:   "cats/mainecoon",
                      body:   file)
    assert_equal 2, client.objects(bucket: bucket, key_prefix: "cats").count
  end

end
