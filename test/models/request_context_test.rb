require "test_helper"

class RequestContextTest < ActiveSupport::TestCase

  class RequestContextSerializerTest < ActiveSupport::TestCase

    setup do
      @instance = RequestContext::RequestContextSerializer.send(:new)
      @context  = RequestContext.new(client_ip:       "1.2.3.4",
                                     client_hostname: "example.net",
                                     user:            users(:northeast),
                                     institution:     institutions(:northeast),
                                     role_limit:      Role::INSTITUTION_ADMINISTRATOR)
    end

    # serialize?()

    test "serialize?() returns false for a non-RequestContext" do
      assert !@instance.serialize?(Time.now)
    end

    test "serialize?() returns true for a RequestContext" do
      assert @instance.serialize?(@context)
    end

    # serialize()

    test "serialize() serializes a RequestContext" do
      hash = @instance.serialize(@context)
      assert_equal @context.client_ip, hash[:client_ip]
      assert_equal @context.client_hostname, hash[:client_hostname]
      assert_equal @context.user, hash[:user]
      assert_equal @context.institution, hash[:institution]
      assert_equal @context.role_limit, hash[:role_limit]
    end

    # deserialize()

    test "deserialize() deserializes a RequestContext" do
      hash = @instance.serialize(@context)
      @context = @instance.deserialize(hash)
      assert_equal @context.client_ip, hash[:client_ip]
      assert_equal @context.client_hostname, hash[:client_hostname]
      assert_equal @context.user, hash[:user]
      assert_equal @context.institution, hash[:institution]
      assert_equal @context.role_limit, hash[:role_limit]
    end

  end

  # initialize()

  test "initialize() works" do
    client_ip       = "1.2.3.4"
    client_hostname = "example.net"
    user            = users(:northeast)
    institution     = institutions(:northeast)
    role_limit      = Role::INSTITUTION_ADMINISTRATOR

    instance        = RequestContext.new(client_ip:       client_ip,
                                         client_hostname: client_hostname,
                                         user:            user,
                                         institution:     institution,
                                         role_limit:      role_limit)
    assert_equal client_ip, instance.client_ip
    assert_equal client_hostname, instance.client_hostname
    assert_equal user, instance.user
    assert_equal institution, instance.institution
    assert_equal role_limit, instance.role_limit
  end

end
