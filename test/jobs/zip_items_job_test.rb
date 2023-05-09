require 'test_helper'

class ZipItemsJobTest < ActiveSupport::TestCase

  setup do
    setup_s3
  end

  test "perform() creates a zip file" do
    item_ids = [items(:uiuc_approved).id, items(:uiuc_multiple_bitstreams).id]
    download = Download.create(institution: institutions(:uiuc))
    ZipItemsJob.new.perform(item_ids, download)

    download.reload
    bucket = ::Configuration.instance.storage[:bucket]
    assert S3Client.instance.head_object(bucket: bucket,
                                         key:    download.object_key).content_length > 0
  end

  test "perform() assigns a correct filename to the zip file" do
    item_ids = [items(:uiuc_approved).id, items(:uiuc_multiple_bitstreams).id]
    download = Download.create(institution: institutions(:uiuc))

    ZipItemsJob.new.perform(item_ids, download)

    download.reload
    assert download.filename.match?(/\Aitems-[a-z\d]{16}.zip\z/)
  end

end
