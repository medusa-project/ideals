require 'test_helper'

class ZipBitstreamsJobTest < ActiveSupport::TestCase

  setup do
    setup_s3
  end

  test "perform() creates a correct Task" do
    bitstreams  = [bitstreams(:southeast_approved_in_permanent),
                   bitstreams(:southeast_item1_license_bundle)]
    download    = Download.create(institution: institutions(:southeast))
    institution = institutions(:southwest)
    user        = users(:southwest)

    ZipBitstreamsJob.perform_now(bitstreams:  bitstreams,
                                 download:    download,
                                 institution: institution,
                                 user:        user)

    task = Task.all.order(created_at: :desc).limit(1).first
    assert_equal "ZipBitstreamsJob", task.name
    assert_equal user, task.user
    assert !task.indeterminate
    assert_not_nil task.started_at
    assert task.status_text.start_with?("Generating")
  end

  test "perform() creates a zip of bitstreams" do
    bitstreams = [bitstreams(:southeast_approved_in_permanent),
                  bitstreams(:southeast_item1_license_bundle)]
    download = Download.create(institution: institutions(:southeast))

    ZipBitstreamsJob.perform_now(bitstreams: bitstreams,
                                 download:   download)

    download.reload
    bucket = ::Configuration.instance.storage[:bucket]
    assert S3Client.instance.head_object(bucket: bucket,
                                         key:    download.object_key).content_length > 0
  end

  test "perform() assigns an existing zip file to the Download instance if
  available" do
    institution = institutions(:southeast)
    bitstreams  = [bitstreams(:southeast_approved_in_permanent),
                   bitstreams(:southeast_item1_license_bundle)]
    download    = Download.create(institution: institution)
    ZipBitstreamsJob.perform_now(bitstreams: bitstreams,
                                 download:   download)

    download = Download.create(institution: institution)
    ZipBitstreamsJob.new.perform(bitstreams: bitstreams,
                                 download:   download)

    download.reload
    bucket = ::Configuration.instance.storage[:bucket]
    assert S3Client.instance.head_object(bucket: bucket,
                                         key:    download.object_key).content_length > 0
  end

  test "perform() assigns a correct filename to the zip file when an item ID
  argument is provided" do
    bitstreams = [bitstreams(:southeast_approved_in_permanent),
                  bitstreams(:southeast_item1_license_bundle)]
    item_id    = bitstreams[0].item.id
    filename   = "item-#{item_id}.zip"
    download   = Download.create(institution: institutions(:southeast),
                                 filename: filename)

    ZipBitstreamsJob.new.perform(bitstreams: bitstreams,
                                 download:   download,
                                 item_id:    item_id)

    download.reload
    assert_equal filename, download.filename
  end

  test "perform() assigns a correct filename to the zip file when an item ID
  argument is not provided" do
    bitstreams = [bitstreams(:southeast_approved_in_permanent),
                  bitstreams(:southeast_item1_license_bundle)]
    download = Download.create(institution: institutions(:southeast))

    ZipBitstreamsJob.perform_now(bitstreams: bitstreams,
                                 download:   download)

    download.reload
    assert download.filename.match?(/\A[a-z\d]{16}.zip\z/)
  end

end
