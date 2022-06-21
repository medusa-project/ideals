require 'test_helper'

class HandleClientTest < ActiveSupport::TestCase

  SUBPREFIX = "ideals"

  setup do
    @client = HandleClient.new
  end

  teardown do
    @client.get_handles.each do |handle|
      @client.delete_handle(handle) if handle.downcase.include?(SUBPREFIX)
    end
  end

  # create_url_handle()

  test "create_url_handle() creates a handle" do
    config = ::Configuration.instance
    prefix = config.handles[:prefix]
    handle = "#{prefix}/#{SUBPREFIX}/test-#{SecureRandom.hex}"
    begin
      # create a handle
      url = "http://example.org/test"
      @client.create_url_handle(handle: handle, url: url)
      # verify that it exists
      struct = @client.get_handle(handle)
      # HS_ADMIN is in demo/production, HS_SECKEY is in dev/test
      assert %w(HS_ADMIN HS_SECKEY).include?(struct[0]['type'])
    ensure
      # clean up
      @client.delete_handle(handle)
    end
  end

  # delete_handle()

  test "delete_handle() deletes a handle" do
    config = ::Configuration.instance
    prefix = config.handles[:prefix]
    handle = "#{prefix}/#{SUBPREFIX}/test-#{SecureRandom.hex}"

    # create a handle
    url = "http://example.org/test"
    @client.create_url_handle(handle: handle, url: url)
    # verify that it exists
    struct = @client.get_handle(handle)
    assert_equal "HS_ADMIN", struct[0]['type']
    # delete it
    @client.delete_handle(handle)
    # verify that it has been deleted
    assert_nil @client.get_handle(handle)
  end

  # exists?()

  test "exists?() returns true for an existing handle" do
    config = ::Configuration.instance
    prefix = config.handles[:prefix]
    handle = "#{prefix}/#{SUBPREFIX}/test-#{SecureRandom.hex}"
    begin
      # create a handle
      url = "http://example.org/test"
      @client.create_url_handle(handle: handle, url: url)
      # verify that it exists
      assert @client.exists?(handle)
    ensure
      # clean up
      @client.delete_handle(handle)
    end
  end

  test "exists?() returns false for a non-existing handle" do
    config = ::Configuration.instance
    prefix = config.handles[:prefix]
    handle = "#{prefix}/bogus-#{SecureRandom.hex}"
    assert !@client.exists?(handle)
  end

  # get_handle()

  test "get_handle() returns the expected handle" do
    config = ::Configuration.instance
    prefix = config.handles[:prefix]
    handle = "#{prefix}/#{SUBPREFIX}/test-#{SecureRandom.hex}"
    begin
      # create a handle
      url = "http://example.org/test"
      @client.create_url_handle(handle: handle, url: url)
      # verify that it exists
      struct = @client.get_handle(handle)
      # HS_ADMIN is in demo/production, HS_SECKEY is in dev/test
      assert %w(HS_ADMIN HS_SECKEY).include?(struct[0]['type'])
    ensure
      # clean up
      @client.delete_handle(handle)
    end
  end

  test "get_handle() returns nil for a nonexistent handle" do
    config = ::Configuration.instance
    prefix = config.handles[:prefix]
    assert_nil @client.get_handle("#{prefix}/bogus-#{SecureRandom.hex}")
  end

  # get_handles()

  test "get_handles() returns the expected handles" do
    config = ::Configuration.instance
    prefix = config.handles[:prefix]
    handle = "#{prefix}/#{SUBPREFIX}/test-#{SecureRandom.hex}"
    begin
      # create a handle
      url = "http://example.org/test"
      @client.create_url_handle(handle: handle, url: url)

      handles = @client.get_handles
      # admin record plus that one and whatever else is lying around
      assert handles.length > 1
    ensure
      # clean up
      @client.delete_handle(handle)
    end
  end

  # list_prefixes()

  test "list_prefixes() returns the expected prefixes" do
    config = ::Configuration.instance
    prefix = config.handles[:prefix]
    handle = "#{prefix}/#{SUBPREFIX}/test-#{SecureRandom.hex}"
    begin
      # create a handle
      url = "http://example.org/test"
      @client.create_url_handle(handle: handle, url: url)

      assert_equal 1, @client.list_prefixes.length
    ensure
      # clean up
      @client.delete_handle(handle)
    end
  end

end