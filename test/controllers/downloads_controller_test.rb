require 'test_helper'

class DownloadsControllerTest < ActionDispatch::IntegrationTest

  setup do
    setup_s3
  end

  # file()

  test "file() returns HTTP 403 when the request IP does not match the
  download's IP" do
    download = downloads(:one)
    download.update!(expired:    false,
                     ip_address: "9.9.9.9")
    get download_file_path(download)
    assert_response :forbidden
  end

  test "file() returns HTTP 410 when the download is expired" do
    download = downloads(:one)
    download.update!(ip_address: "127.0.0.1",
                     expired:    true)
    get download_file_path(download)
    assert_response :forbidden # TODO: modify policy classes to support a :status result key in order to be able to change this to :gone
  end

  test "file() returns HTTP 404 when the download has no corresponding file" do
    download = downloads(:one)
    download.update!(filename: nil)
    get download_file_path(download)
    assert_response :not_found
  end

  test "file() redirects to a download URL" do
    File.open(file_fixture("crane.jpg"), "r") do |file|
      S3Client.instance.put_object(bucket: ::Configuration.instance.storage[:bucket],
                                   key:    "#{Download::DOWNLOADS_KEY_PREFIX}file.txt",
                                   body:   file)
      download = Download.create!(filename:   "file.txt",
                                  ip_address: "127.0.0.1")
      get download_file_path(download)
      assert_response :see_other
    end
  end

  # show()

  test "show() returns HTTP 403 when the request IP does not match the
  download's IP" do
    download = downloads(:one)
    download.update!(expired:    false,
                     ip_address: "9.9.9.9")
    get download_path(download)
    assert_response :forbidden
  end

  test "show() returns HTTP 410 when the download is expired" do
    download = downloads(:one)
    download.update!(expired: true)
    get download_path(download)
    assert_response :forbidden # TODO :see above todo
  end

  test "show() returns HTTP 200" do
    download = downloads(:one)
    get download_path(download)
    assert_response :ok
  end

end
