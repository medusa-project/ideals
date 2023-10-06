require 'test_helper'

class DownloadTest < ActiveSupport::TestCase

  setup do
    @download = downloads(:southeast_one)
    setup_s3
  end

  # cleanup()

  test "cleanup() works properly" do
    Download.destroy_all

    d1 = Download.create(institution: institutions(:southeast))
    d2 = Download.create(institution: institutions(:southeast))
    d3 = Download.create(institution: institutions(:southeast))

    assert_equal 0, Download.where(expired: true).count

    d1.update(updated_at: 28.hours.ago)

    Download.cleanup(60 * 60 * 24) # 1 day

    assert_equal 1, Download.where(expired: true).count
  end

  # create()

  test "key is assigned at creation" do
    @download = Download.create!(institution: institutions(:southeast))
    assert @download.key.length > 20
  end

  # expire()

  test "expire() deletes the corresponding storage object" do
    store       = ObjectStore.instance
    institution = institutions(:southeast)
    File.open(file_fixture("crane.jpg"), "r") do |file|
      download = Download.create!(filename:    "file.jpg",
                                  institution: institution)
      store.put_object(key:  download.object_key,
                       file: file)
      download.expire
      assert !store.object_exists?(key: download.object_key)
    end
  end

  test "expire() sets the expired property to true" do
    @download.expire
    assert @download.expired
  end

  # object_key()

  test "object_key() returns nil if there is no associated Institution" do
    @download.institution = nil
    assert_nil @download.object_key
  end

  test "object_key() returns nil if the filename is not set" do
    @download.filename = nil
    assert_nil @download.object_key
  end

  test "object_key() returns a correct value" do
    assert_equal "institutions/#{@download.institution.key}/downloads/#{@download.filename}",
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
