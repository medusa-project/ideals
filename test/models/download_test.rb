require 'test_helper'

class DownloadTest < ActiveSupport::TestCase

  setup do
    @download = downloads(:one)
  end

  # cleanup()

  test 'cleanup() works properly' do
    Download.destroy_all

    d1 = Download.create
    d2 = Download.create
    d3 = Download.create

    assert_equal 0, Download.where(expired: true).count

    d1.update(updated_at: 28.hours.ago)

    Download.cleanup(60 * 60 * 24) # 1 day

    assert_equal 1, Download.where(expired: true).count
  end

  # create()

  test "key is assigned at creation" do
    @download = Download.create!
    assert @download.key.length > 20
  end

  # expire()

  test "expire() deletes the corresponding storage object" do
    client = S3Client.instance
    bucket = ::Configuration.instance.storage[:bucket]
    key    = "#{Download::DOWNLOADS_KEY_PREFIX}file.jpg"
    File.open(file_fixture("crane.jpg"), "r") do |file|
      client.put_object(bucket: bucket,
                        key:    key,
                        body:   file)
      download = Download.create!(filename: "file.jpg")
      download.expire
      assert !client.object_exists?(bucket: bucket, key: key)
    end
  end

  test "expire() sets the expired property to true" do
    @download.expire
    assert @download.expired
  end

  # object_key()

  test 'object_key() returns a correct value' do
    assert_equal Download::DOWNLOADS_KEY_PREFIX + @download.filename,
                 @download.object_key
  end

  # presigned_url()

  test "presigned_url() returns a URL" do
    assert_not_nil @download.presigned_url
  end

  # ready?()

  test 'ready?() returns a correct value' do
    @download.task     = Task.new(status: Task::Status::RUNNING)
    @download.filename = "file.txt"
    assert !@download.ready?

    @download.task     = Task.new(status: Task::Status::SUCCEEDED)
    @download.filename = nil
    assert !@download.ready?

    @download.task.status = Task::Status::SUCCEEDED
    @download.filename    = "file.txt"
    assert @download.ready?
  end

end
