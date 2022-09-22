require 'test_helper'

class ZipBitstreamsJobTest < ActiveSupport::TestCase

  setup do
    setup_s3
  end

  test "perform() creates a zip of bitstreams" do
    bitstreams = [bitstreams(:approved_in_permanent),
                  bitstreams(:license_bundle)]
    download = Download.create(institution: institutions(:uiuc))

    ZipBitstreamsJob.new.perform(bitstreams, download)

    download.reload
    bucket = ::Configuration.instance.storage[:bucket]
    assert S3Client.instance.head_object(bucket: bucket,
                                         key:    download.object_key).content_length > 0
  end

  test "perform() assigns an existing zip file to the Download instance if
  available" do
    institution = institutions(:uiuc)
    bitstreams  = [bitstreams(:approved_in_permanent),
                   bitstreams(:license_bundle)]
    download    = Download.create(institution: institution)
    ZipBitstreamsJob.new.perform(bitstreams, download)

    download = Download.create(institution: institution)
    ZipBitstreamsJob.new.perform(bitstreams, download)

    download.reload
    bucket = ::Configuration.instance.storage[:bucket]
    assert S3Client.instance.head_object(bucket: bucket,
                                         key:    download.object_key).content_length > 0
  end

  test "perform() assigns a correct filename to the zip file when an item ID
  argument is provided" do
    filename   = "item-1234.zip"
    bitstreams = [bitstreams(:approved_in_permanent),
                  bitstreams(:license_bundle)]
    download   = Download.create(institution: institutions(:uiuc),
                                 filename: filename)

    ZipBitstreamsJob.new.perform(bitstreams, download, 1234)

    download.reload
    assert_equal filename, download.filename
  end

  test "perform() assigns a correct filename to the zip file when an item ID
  argument is not provided" do
    bitstreams = [bitstreams(:approved_in_permanent),
                  bitstreams(:license_bundle)]
    download = Download.create(institution: institutions(:uiuc))

    ZipBitstreamsJob.new.perform(bitstreams, download)

    download.reload
    assert download.filename.match?(/^[a-z\d]{16}.zip$/)
  end

end
