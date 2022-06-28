require 'test_helper'

class HandleTest < ActiveSupport::TestCase

  setup do
    @instance = handles(:handle1)
  end

  # prefix()

  test "prefix() returns the prefix from the configuration" do
    assert_equal ::Configuration.instance.handles[:prefix], Handle.prefix
  end

  # set_suffix_start()

  test "set_suffix_start() updates the suffix sequence" do
    Handle.set_suffix_start(54)
    handle = Handle.new
    handle.item = items(:item1)
    handle.transient = true
    handle.save
    handle.reload
    assert_equal 54, handle.suffix
  end

  # create()

  test "create() puts the handle to the handle server" do
    client = HandleClient.new
    handle = Handle.create!(item: items(:described))
    begin
      assert client.exists?(handle)
    ensure
      client.delete_handle(handle)
    end
  end

  # delete_from_server()

  test "delete_from_server() deletes the handle from the handle server" do
    client = HandleClient.new
    assert !client.exists?(@instance.handle)
    @instance.put_to_server
    assert client.exists?(@instance.handle)
    @instance.delete_from_server
    assert !client.exists?(@instance.handle)
  end

  # exists_on_server?()

  test "exists_on_server?() deletes the handle from the handle server" do
    begin
      assert !@instance.exists_on_server?
      @instance.put_to_server
      assert @instance.exists_on_server?
    ensure
      @instance.delete_from_server
    end
  end

  # handle()

  test "handle() returns a correct value" do
    assert_equal sprintf("%s/%s",
                         ::Configuration.instance.handles[:prefix],
                         @instance.suffix),
                 @instance.handle
  end

  # handle_net_url()

  test "handle_net_url() returns a correct value" do
    expected = ["https://hdl.handle.net/", @instance.handle].join
    assert_equal expected, @instance.handle_net_url
  end

  # put_to_server()

  test "put_to_server() saves a valid handle to the handle server" do
    client = HandleClient.new
    begin
      assert !client.exists?(@instance.handle)
      @instance.put_to_server
      assert client.exists?(@instance.handle)
    ensure
      client.delete_handle(@instance)
    end
  end

  # url()

  test "url() returns a correct value" do
    expected = sprintf("%s/%s",
            ::Configuration.instance.handles[:base_url],
            @instance.handle)
    assert_equal expected, @instance.url
  end

  # validate()

  test "validate() ensures that the instance must be associated with an entity" do
    assert @instance.validate
    @instance.item = nil
    assert !@instance.validate
  end

  test "validate() ensures that the instance is not associated with more than one entity" do
    assert @instance.validate
    @instance.unit = units(:unit1)
    assert !@instance.validate
  end

end
