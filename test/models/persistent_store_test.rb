require "test_helper"

class PersistentStoreTest < ActiveSupport::TestCase

  setup do
    bucket = ::Configuration.instance.storage[:bucket]
    client = S3Client.instance
    unless client.bucket_exists?(bucket)
      client.create_bucket(bucket: bucket)
    end
  end

  teardown do
    bucket = ::Configuration.instance.storage[:bucket]
    S3Client.instance.delete_objects(bucket: bucket, key_prefix: "/")
  end

  # copy_object()

  test "copy_object() copies an object" do
    store = PersistentStore.instance
    file  = File.join(Rails.root, "test", "fixtures", "files", "escher_lego.png")
    store.put_object(key:  "cats/siamese", path: file)
    store.copy_object(source_key: "cats/siamese", target_key: "cats/mainecoon")
    assert store.object_exists?(key: "cats/mainecoon")
  end

  test "copy_object() copies the ACL of the copied object" do
    skip # we can't test this because MinIO doesn't support ACLs
  end

  # delete_object()

  test "delete_object() deletes an object" do
    store = PersistentStore.instance
    file  = File.join(Rails.root, "test", "fixtures", "files", "escher_lego.png")
    key   = "cats/siamese"
    store.put_object(key: key, path: file)
    store.delete_object(key: key)
    assert !store.object_exists?(key: key)
  end

  # delete_objects()

  test "delete_objects() deletes all intended objects" do
    store = PersistentStore.instance
    file  = File.join(Rails.root, "test", "fixtures", "files", "escher_lego.png")
    store.put_object(key:  "cats/siamese", path: file)
    store.put_object(key:  "cats/mainecoon", path: file)
    store.put_object(key:  "dogs", path: file)

    store.delete_objects(key_prefix: "cats")

    assert !store.object_exists?(key: "cats/siamese")
    assert !store.object_exists?(key: "cats/mainecoon")
    assert store.object_exists?(key: "dogs")
  end

  # get_object()

  test "get_object() can download an object into memory" do
    store = PersistentStore.instance
    file  = File.join(Rails.root, "test", "fixtures", "files", "escher_lego.png")
    key   = "cats/siamese"
    store.put_object(key: key, path: file)
    assert store.get_object(key: key).length > 5000
  end

  test "get_object() can download an object to a file" do
    store = PersistentStore.instance
    file  = File.join(Rails.root, "test", "fixtures", "files", "escher_lego.png")
    key   = "cats/siamese"
    store.put_object(key: key, path: file)
    Tempfile.open("test") do |tempfile|
      store.get_object(key: key, response_target: tempfile.path)
      assert tempfile.size > 5000
    end
  end

  test "get_object() raises an error when given a nonexistent key" do
    store = PersistentStore.instance
    assert_raises do
      store.get_object(key: "bogus")
    end
  end

  # move_object()

  test "move_object() copies an object" do
    store = PersistentStore.instance
    file  = File.join(Rails.root, "test", "fixtures", "files", "escher_lego.png")
    source_key = "cats/siamese"
    target_key = "cats/mainecoon"
    store.put_object(key: source_key, path: file)
    store.move_object(source_key: source_key, target_key: target_key)
    assert store.object_exists?(key: target_key)
    assert !store.object_exists?(key: source_key)
  end

  test "move_object() deletes the source object" do
    store      = PersistentStore.instance
    file       = File.join(Rails.root, "test", "fixtures", "files", "escher_lego.png")
    source_key = "cats/siamese"
    target_key = "cats/mainecoon"
    store.put_object(key:  source_key, path: file)
    store.move_object(source_key: source_key, target_key: target_key)
    assert !store.object_exists?(key: source_key)
  end

  test "move_object() copies the ACL of the copied object if told to" do
    skip # we can't test this because MinIO doesn't support ACLs
  end

  test "move_object() does not copy the ACL of the copied object if told not to" do
    skip # we can't test this because MinIO doesn't support ACLs
  end

  # object_count()

  test "object_count() returns a correct count" do
    store = PersistentStore.instance
    file  = File.join(Rails.root, "test", "fixtures", "files", "escher_lego.png")
    store.put_object(key: "cats/siamese", path: file)
    store.put_object(key: "cats/mainecoon", path: file)
    assert_equal 2, store.object_count(key_prefix: "cats")
  end

  # object_exists?()

  test "object_exists?() returns true when the object exists" do
    key   = "test-#{SecureRandom.hex}"
    store = PersistentStore.instance
    store.put_object(key:  key,
                     path: File.join(Rails.root, "test", "fixtures", "files", "escher_lego.png"))
    assert store.object_exists?(key: key)
  end

  test "object_exists?() returns false when the object does not exist" do
    assert !PersistentStore.instance.object_exists?(key: "bogus")
  end

  # object_length()

  test "object_length() returns the object length" do
    key   = "test"
    store = PersistentStore.instance
    store.put_object(key:  key,
                     path: File.join(Rails.root, "test", "fixtures", "files", "escher_lego.png"))
    assert store.object_length(key: key) > 5000
  end

  test "object_exists?() raises an error when the object does not exist" do
    assert_raises do
      PersistentStore.instance.object_length(key: "bogus")
    end
  end

  # objects()

  test "objects() returns a correct value" do
    store = PersistentStore.instance
    file  = File.join(Rails.root, "test", "fixtures", "files", "escher_lego.png")
    store.put_object(key: "cats/siamese", path: file)
    store.put_object(key: "cats/mainecoon", path: file)
    assert_equal 2, store.objects(key_prefix: "cats").count
  end

  # presigned_download_url()

  test "presigned_download_url() returns a presigned URL" do
    store = PersistentStore.instance
    file  = File.join(Rails.root, "test", "fixtures", "files", "escher_lego.png")
    key   = "cats/siamese"
    store.put_object(key: key, path: file)
    assert_not_empty store.presigned_download_url(key:        key,
                                                  expires_in: 1.minute.to_i)
  end

  test "presigned_upload_url() returns a presigned URL" do
    store = PersistentStore.instance
    key   = "cats/siamese"
    assert_not_empty store.presigned_upload_url(key:        key,
                                                expires_in: 1.minute.to_i)
  end

  # public_url()

  test "public_url() returns a URL" do
    store = PersistentStore.instance
    file  = File.join(Rails.root, "test", "fixtures", "files", "escher_lego.png")
    key   = "cats/siamese"
    store.put_object(key: key, path: file)
    assert_not_empty store.public_url(key: key)
  end

  # put_object()

  test "put_object() uploads the given pathname" do
    store = PersistentStore.instance
    file  = File.join(Rails.root, "test", "fixtures", "files", "escher_lego.png")
    key   = "cats/siamese"
    store.put_object(key: key, path: file)
    assert store.object_exists?(key: key)
  end

  test "put_object() uploads the given file" do
    store = PersistentStore.instance
    file  = File.new(File.join(Rails.root, "test", "fixtures", "files", "escher_lego.png"))
    key   = "cats/siamese"
    store.put_object(key: key, file: file)
    assert store.object_exists?(key: key)
  end

  test "put_object() uploads the given IO" do
    store = PersistentStore.instance
    File.open(File.join(Rails.root, "test", "fixtures", "files", "escher_lego.png"), "r") do |file|
      key   = "cats/siamese"
      store.put_object(key: key, io: file)
      assert store.object_exists?(key: key)
    end
  end

  test "put_object() uploads the given string" do
    store = PersistentStore.instance
    key   = "cats/siamese"
    store.put_object(key: key, data: "some data")
    assert store.object_exists?(key: key)
  end

  test "put_object() sets the ACL of the uploaded object if the public argument
  is true" do
    skip # we can't test this because MinIO doesn't support ACLs
  end

  test "put_object() does not set the ACL of the uploaded object if the public
  argument is false" do
    skip # we can't test this because MinIO doesn't support ACLs
  end

  test "put_object() sets tags on the uploaded object" do
    store = PersistentStore.instance
    file  = File.join(Rails.root, "test", "fixtures", "files", "escher_lego.png")
    key   = "institutions/ins1/test"
    store.put_object(key: key, path: file)

    bucket   = ::Configuration.instance.storage[:bucket]
    response = S3Client.instance.get_object_tagging(bucket: bucket, key: key)
    tag      = response.to_h[:tag_set][0]
    assert_equal "institution_key", tag[:key]
    assert_equal "ins1", tag[:value]
  end

  # upload_path()

  test "upload_path() uploads correct objects with correct keys" do
    root_path = File.join(Rails.root, "test", "fixtures", "saf_packages", "valid_item")
    store     = PersistentStore.instance
    store.upload_path(root_path:  root_path,
                       key_prefix: "prefix/")

    assert_equal 5, store.object_count(key_prefix: "prefix/")
    assert store.object_exists?(key: "prefix/item_1/content")
    assert store.object_exists?(key: "prefix/item_1/dublin_core.xml")
    assert store.object_length(key: "prefix/item_1/dublin_core.xml") > 0
  end

end
