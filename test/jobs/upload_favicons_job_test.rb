require 'test_helper'

class UploadFaviconsJobTest < ActiveSupport::TestCase

  setup do
    setup_s3
  end

  test "perform() uploads favicons" do
    Dir.mktmpdir do |tmpdir|
      path = File.join(tmpdir, "escher_lego.jpg")
      FileUtils.cp(file_fixture("escher_lego.jpg"), path)

      institution = institutions(:southwest)
      UploadFaviconsJob.new.perform(path, institution)

      institution.reload
      # Favicon processing & uploading functionality is tested more thoroughly
      # in the test of Institution.upload_favicon().
      assert institution.has_favicon
    end
  end

end
