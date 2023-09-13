require 'test_helper'

class GenerateDerivativeImageJobTest < ActiveSupport::TestCase

  setup do
    setup_s3
  end

  test "perform() generates a derivative image" do
    bs = bitstreams(:uiuc_approved_in_permanent)

    GenerateDerivativeImageJob.perform_now(bs, :full, 512, :jpg)

    key = bs.send(:derivative_image_key, region: :full, size: 512, format: :jpg)
    assert PersistentStore.instance.object_exists?(key: key)
  end

end
