require 'test_helper'

class DownloadPolicyTest < ActiveSupport::TestCase

  setup do
    @download = downloads(:southwest_one)
  end

  # file?()

  test "file?() does not authorize an incorrect scope" do
    context = RequestContext.new(user:        users(:southwest_admin),
                                 institution: institutions(:northeast))
    policy  = DownloadPolicy.new(context, @download)
    assert !policy.file?
  end

  test "file?() restricts downloads whose IP address does not match the client
  IP address" do
    context = RequestContext.new(user:        nil,
                                 client_ip:   "9.9.9.9",
                                 institution: @download.institution)
    policy  = DownloadPolicy.new(context, @download)
    assert !policy.file?
  end

  test "file?() restricts expired downloads" do
    @download = downloads(:expired)
    context   = RequestContext.new(user:        nil,
                                   client_ip:   @download.ip_address,
                                   institution: @download.institution)
    policy    = DownloadPolicy.new(context, @download)
    assert !policy.file?
  end

  test "file?() restricts even sysadmins from expired downloads" do
    @download = downloads(:expired)
    user      = users(:southwest_sysadmin)
    context   = RequestContext.new(user:        user,
                                   client_ip:   @download.ip_address,
                                   institution: @download.institution)
    policy    = DownloadPolicy.new(context, @download)
    assert !policy.file?
  end

  test "file?() authorizes sysadmins to downloads with different IP
  addresses" do
    user    = users(:southwest_sysadmin)
    context = RequestContext.new(user:        user,
                                 client_ip:   "9.9.9.9",
                                 institution: @download.institution)
    policy  = DownloadPolicy.new(context, @download)
    assert policy.file?
  end

  # show?()

  test "show?() does not authorize an incorrect scope" do
    context = RequestContext.new(user:        users(:southwest_admin),
                                 institution: institutions(:northeast))
    policy  = DownloadPolicy.new(context, @download)
    assert !policy.show?
  end

  test "show?() restricts downloads whose IP address does not match the client
  IP address" do
    context = RequestContext.new(user:        nil,
                                 client_ip:   "9.9.9.9",
                                 institution: @download.institution)
    policy  = DownloadPolicy.new(context, @download)
    assert !policy.show?
  end

  test "show?() restricts expired downloads" do
    @download = downloads(:expired)
    context   = RequestContext.new(user:        nil,
                                   client_ip:   @download.ip_address,
                                   institution: @download.institution)
    policy    = DownloadPolicy.new(context, @download)
    assert !policy.show?
  end

  test "show?() restricts even sysadmins from expired downloads" do
    @download = downloads(:expired)
    user      = users(:southwest_sysadmin)
    context   = RequestContext.new(user:        user,
                                   client_ip:   @download.ip_address,
                                   institution: @download.institution)
    policy    = DownloadPolicy.new(context, @download)
    assert !policy.show?
  end

  test "show?() authorizes sysadmins to downloads with different IP
  addresses" do
    user    = users(:southwest_sysadmin)
    context = RequestContext.new(user:        user,
                                 client_ip:   "9.9.9.9",
                                 institution: @download.institution)
    policy  = DownloadPolicy.new(context, @download)
    assert policy.show?
  end

  test "show?() authorizes everyone to downloads with no IP address set" do
    @download.update!(ip_address: nil)
    context = RequestContext.new(user:        nil,
                                 client_ip:   "9.9.9.9",
                                 institution: @download.institution)
    policy  = DownloadPolicy.new(context, @download)
    assert policy.show?
  end

end
