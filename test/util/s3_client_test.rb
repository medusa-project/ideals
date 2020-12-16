require 'test_helper'

class S3ClientTest < ActiveSupport::TestCase

  # bucket_exists?()

  test "bucket_exists?() returns true when the bucket exists" do
    bucket = ::Configuration.instance.aws[:bucket]
    assert S3Client.instance.bucket_exists?(bucket)
  end

  test "bucket_exists?() returns false when the bucket does not exist" do
    assert !S3Client.instance.bucket_exists?("bogus")
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

end
