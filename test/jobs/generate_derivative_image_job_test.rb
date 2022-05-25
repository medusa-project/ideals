require 'test_helper'

class GenerateDerivativeImageJobTest < ActiveSupport::TestCase

  setup do
    setup_s3
  end

  test "perform() generates a derivative image" do
    bs = bitstreams(:approved_in_permanent)
    # upload the source image to the permanent area of the application S3 bucket
    File.open(file_fixture("escher_lego.jpg"), "r") do |file|
      bs.upload_to_permanent(file)
    end

    GenerateDerivativeImageJob.perform_now(bs, :full, 512, :jpg)

    config = ::Configuration.instance
    bucket = config.storage[:bucket]
    key    = bs.send(:derivative_key, region: :full, size: 512, format: :jpg)
    assert S3Client.instance.object_exists?(bucket: bucket, key: key)
  end

end
