require 'test_helper'

class ZipItemsJobTest < ActiveSupport::TestCase

  setup do
    setup_s3
  end

  test "perform() creates a correct Task" do
    item_ids    = [items(:southeast_approved).id, items(:southeast_multiple_bitstreams).id]
    download    = Download.create(institution: institutions(:southeast))
    institution = institutions(:southeast)
    user        = users(:southeast)
    ZipItemsJob.new.perform(item_ids:    item_ids,
                            download:    download,
                            institution: institution,
                            user:        user)

    task = Task.all.order(created_at: :desc).limit(1).first
    assert_equal "ZipItemsJob", task.name
    assert_equal institution, task.institution
    assert_equal user, task.user
    assert !task.indeterminate
    assert task.status_text.start_with?("Generating")
  end

  test "perform() creates a zip file" do
    item_ids = [items(:southeast_approved).id, items(:southeast_multiple_bitstreams).id]
    download = Download.create(institution: institutions(:southeast))
    ZipItemsJob.new.perform(item_ids: item_ids,
                            download: download)

    download.reload
    bucket = ::Configuration.instance.storage[:bucket]
    assert S3Client.instance.head_object(bucket: bucket,
                                         key:    download.object_key).content_length > 0
  end

  test "perform() assigns a correct filename to the zip file" do
    item_ids = [items(:southeast_approved).id, items(:southeast_multiple_bitstreams).id]
    download = Download.create(institution: institutions(:southeast))

    ZipItemsJob.new.perform(item_ids: item_ids,
                            download: download)

    download.reload
    assert download.filename.match?(/\Aitems-[a-z\d]{16}.zip\z/)
  end

end
