require 'test_helper'

class CredentialPolicyTest < ActiveSupport::TestCase

  setup do
    @credential = credentials(:southwest)
  end

  # create?()

  test "create?() returns false with a nil user" do
    policy = CredentialPolicy.new(nil, Credential)
    assert !policy.create?
  end

  test "create?() does not authorize non-sysadmins" do
    user    = users(:southwest)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = CredentialPolicy.new(context, Credential)
    assert !policy.create?
  end

  test "create?() authorizes sysadmins" do
    user    = users(:southwest_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = CredentialPolicy.new(context, Credential)
    assert policy.create?
  end

  test "create?() respects role limits" do
    # sysadmin user limited to an insufficient role
    user    = users(:southwest_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::LOGGED_IN)
    policy  = CredentialPolicy.new(context, Credential)
    assert !policy.create?
  end

  # edit_password?()

  test "edit_password?() returns false with a nil request context" do
    context = RequestContext.new(user:        nil,
                                 institution: @credential.user.institution)
    policy = CredentialPolicy.new(context, @credential)
    assert !policy.edit_password?
  end

  test "edit_password?() does not authorize an incorrect scope" do
    context = RequestContext.new(user:        users(:southwest_admin),
                                 institution: institutions(:northeast))
    policy  = CredentialPolicy.new(context, @credential)
    assert !policy.edit_password?
  end

  test "edit_password?() does not authorize non-sysadmins other than the user
  being edited" do
    user    = users(:southwest_saml)
    context = RequestContext.new(user:        user,
                                 institution: @credential.user.institution)
    policy  = CredentialPolicy.new(context, @credential)
    assert !policy.edit_password?
  end

  test "edit_password?() does not authorize sysadmins other than the user
  being edited" do
    user    = users(:southwest_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = CredentialPolicy.new(context, @credential)
    assert !policy.edit_password?
  end

  test "edit_password?() authorizes the same user as the one being edited" do
    user    = users(:southwest)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = CredentialPolicy.new(context, @credential)
    assert policy.edit_password?
  end

  test "edit_password?() respects role limits" do
    # sysadmin user limited to an insufficient role
    user    = users(:southwest_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::LOGGED_IN)
    policy  = CredentialPolicy.new(context, @credential)
    assert !policy.edit_password?
  end

  # new?()

  test "new?() returns false with a nil user" do
    policy = CredentialPolicy.new(nil, Credential)
    assert !policy.new?
  end

  test "new?() does not authorize non-sysadmins" do
    user    = users(:southwest)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = CredentialPolicy.new(context, Credential)
    assert !policy.new?
  end

  test "new?() authorizes sysadmins" do
    user    = users(:southwest_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = CredentialPolicy.new(context, Credential)
    assert policy.new?
  end

  test "new?() respects role limits" do
    # sysadmin user limited to an insufficient role
    user    = users(:southwest_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::LOGGED_IN)
    policy  = CredentialPolicy.new(context, Credential)
    assert !policy.new?
  end

  # new_password?()

  test "new_password?() returns true with a nil user" do
    context = RequestContext.new(user:        nil,
                                 institution: @credential.user.institution)
    policy = CredentialPolicy.new(context, @credential)
    assert policy.new_password?
  end

  test "new_password?() does not authorize an incorrect scope" do
    context = RequestContext.new(user:        users(:southwest_admin),
                                 institution: institutions(:northeast))
    policy  = CredentialPolicy.new(context, @credential)
    assert !policy.new_password?
  end

  test "new_password?() authorizes everyone" do
    user    = users(:southwest)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = CredentialPolicy.new(context, @credential)
    assert policy.new_password?
  end

  # register?()

  test "register?() returns true with a nil user" do
    context = RequestContext.new(user:        nil,
                                 institution: @credential.user.institution)
    policy = CredentialPolicy.new(context, @credential)
    assert policy.register?
  end

  test "register?() does not authorize an incorrect scope" do
    context = RequestContext.new(user:        users(:southwest_admin),
                                 institution: institutions(:northeast))
    policy  = CredentialPolicy.new(context, @credential)
    assert !policy.register?
  end

  test "register?() authorizes everyone" do
    user    = users(:southwest)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = CredentialPolicy.new(context, @credential)
    assert policy.register?
  end

  # reset_password?()

  test "reset_password?() returns true with a nil user" do
    context = RequestContext.new(user:        nil,
                                 institution: @credential.user.institution)
    policy = CredentialPolicy.new(context, @credential)
    assert policy.reset_password?
  end

  test "reset_password?() does not authorize an incorrect scope" do
    context = RequestContext.new(user:        users(:southwest_admin),
                                 institution: institutions(:northeast))
    policy  = CredentialPolicy.new(context, @credential)
    assert !policy.reset_password?
  end

  test "reset_password?() authorizes everyone" do
    user    = users(:southwest)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = CredentialPolicy.new(context, @credential)
    assert policy.reset_password?
  end

  # update?()

  test "update?() returns true with a nil user" do
    context = RequestContext.new(user:        nil,
                                 institution: @credential.user.institution)
    policy = CredentialPolicy.new(context, @credential)
    assert policy.update?
  end

  test "update?() does not authorize an incorrect scope" do
    context = RequestContext.new(user:        users(:southwest_admin),
                                 institution: institutions(:northeast))
    policy  = CredentialPolicy.new(context, @credential)
    assert !policy.update?
  end

  test "update?() authorizes everyone" do
    user    = users(:southwest)
    context = RequestContext.new(user:        user,
                                 institution: @credential.user.institution)
    policy  = CredentialPolicy.new(context, @credential)
    assert policy.update?
  end

  # update_password?()

  test "update_password?() returns false with a nil request context" do
    context = RequestContext.new(user:        nil,
                                 institution: @credential.user.institution)
    policy = CredentialPolicy.new(context, @credential)
    assert !policy.update_password?
  end

  test "update_password?() does not authorize an incorrect scope" do
    context = RequestContext.new(user:        users(:southwest_admin),
                                 institution: institutions(:northeast))
    policy  = CredentialPolicy.new(context, @credential)
    assert !policy.update_password?
  end

  test "update_password?() does not authorize non-sysadmins other than the user
  being updated" do
    user    = users(:southwest_saml)
    context = RequestContext.new(user:        user,
                                 institution: @credential.user.institution)
    policy = CredentialPolicy.new(context, @credential)
    assert !policy.update_password?
  end

  test "update_password?() does not authorize sysadmins other than the user
  being updated" do
    user    = users(:southwest_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy = CredentialPolicy.new(context, @credential)
    assert !policy.update_password?
  end

  test "update_password?() authorizes the same user" do
    user    = users(:southwest)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy = CredentialPolicy.new(context, @credential)
    assert policy.update_password?
  end

  test "update_password?() respects role limits" do
    # sysadmin user limited to an insufficient role
    user    = users(:southwest_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = CredentialPolicy.new(context, @credential)
    assert !policy.update_password?
  end

end
