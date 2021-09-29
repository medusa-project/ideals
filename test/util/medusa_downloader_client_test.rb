require 'test_helper'

class MedusaDownloaderClientTest < ActiveSupport::TestCase

  def setup
    @instance = MedusaDownloaderClient.new
  end

  # download_url()

  test "download_url() raises an error when given an illegal item argument" do
    assert_raises ArgumentError do
      @instance.download_url(item: nil)
    end
  end

  test 'download_url() raises an error when given an item with no downloadable
  bitstreams' do
    assert_raises ArgumentError do
      @instance.download_url(item: items(:undescribed))
    end
  end

  # head()

  test 'head() works' do
    skip if ENV['CI'] == '1' # CI does not have access to the Downloader
    assert_nothing_raised do
      @instance.head
    end
  end

end
