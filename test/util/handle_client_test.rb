require 'test_helper'

class HandleClientTest < ActiveSupport::TestCase

  setup do
    @client = HandleClient.new
  end

  # create_url_handle()

  test "create_url_handle() creates a handle" do
    skip if Rails.env.ci? # TODO: get a handle server working in CI

    config = ::Configuration.instance
    skip unless config.handles[:api][:basic_user].present?

    prefix = config.handles[:prefix]
    handle = "#{prefix}/ideals-test-#{SecureRandom.hex}"
    begin
      # create a handle
      url = "http://example.org/test"
      @client.create_url_handle(handle: handle, url: url)
      # verify that it exists
      struct = @client.get_handle(handle)
      assert_equal "HS_ADMIN", struct[0]['type']
    ensure
      # clean up
      @client.delete_handle(handle)
    end
  end

  # delete_handle()

  test "delete_handle() deletes a handle" do
    skip if Rails.env.ci? # TODO: get a handle server working in CI

    config = ::Configuration.instance
    skip unless config.handles[:api][:basic_user].present?

    prefix = config.handles[:prefix]
    handle = "#{prefix}/ideals-test-#{SecureRandom.hex}"

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
    skip if Rails.env.ci? # TODO: get a handle server working in CI

    config = ::Configuration.instance
    skip unless config.handles[:api][:basic_user].present?

    prefix = config.handles[:prefix]
    handle = "#{prefix}/ideals-test-#{SecureRandom.hex}"
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
    skip if Rails.env.ci? # TODO: get a handle server working in CI

    config = ::Configuration.instance
    prefix = config.handles[:prefix]
    handle = "#{prefix}/bogus-#{SecureRandom.hex}"
    assert !@client.exists?(handle)
  end

  # get_handle()

  test "get_handle() returns the expected handle" do
    skip if Rails.env.ci? # TODO: get a handle server working in CI

    config = ::Configuration.instance
    skip unless config.handles[:api][:basic_user].present?

    prefix  = config.handles[:prefix]
    handles = @client.get_handles(prefix)
    handle  = @client.get_handle(handles[0])
    assert_equal "HS_ADMIN", handle[0]['type']
  end

  test "get_handle() returns nil for a nonexistent handle" do
    skip if Rails.env.ci? # TODO: get a handle server working in CI

    config = ::Configuration.instance
    skip unless config.handles[:api][:basic_user].present?

    prefix  = config.handles[:prefix]
    assert_nil @client.get_handle("#{prefix}/bogus-bogus-bogus")
  end

  # get_handles()

  test "get_handles() returns the expected handles" do
    skip if Rails.env.ci? # TODO: get a handle server working in CI

    config = ::Configuration.instance
    skip unless config.handles[:api][:basic_user].present?

    prefix  = config.handles[:prefix]
    handles = @client.get_handles(prefix)
    assert handles.length > 1
  end

end