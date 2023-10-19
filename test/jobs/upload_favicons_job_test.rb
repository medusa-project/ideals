require 'test_helper'

class UploadFaviconsJobTest < ActiveSupport::TestCase

  setup do
    setup_s3
  end

  test "perform() creates a correct Task" do
    Dir.mktmpdir do |tmpdir|
      path = File.join(tmpdir, "escher_lego.png")
      FileUtils.cp(file_fixture("escher_lego.png"), path)

      institution = institutions(:southwest)
      user        = users(:southwest)
      UploadFaviconsJob.perform_now(master_favicon_path: path,
                                    institution:         institution,
                                    user:                user)

      task = Task.all.order(created_at: :desc).limit(1).first
      assert_equal "UploadFaviconsJob", task.name
      assert_equal institution, task.institution
      assert_equal user, task.user
      assert !task.indeterminate
      assert_not_nil task.started_at
      assert_equal "Processing favicons", task.status_text
    end
  end

  test "perform() uploads favicons" do
    Dir.mktmpdir do |tmpdir|
      path = File.join(tmpdir, "escher_lego.png")
      FileUtils.cp(file_fixture("escher_lego.png"), path)

      institution = institutions(:southwest)
      UploadFaviconsJob.new.perform(master_favicon_path: path,
                                    institution:         institution)

      institution.reload
      # Favicon processing & uploading functionality is tested more thoroughly
      # in the test of Institution.upload_favicon().
      assert institution.has_favicon
    end

  end

end
