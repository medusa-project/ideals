require 'test_helper'

class MetadataProfileElementPolicyTest < ActiveSupport::TestCase

  setup do
    @element = metadata_profile_elements(:southwest_default_title)
  end

  # create?()

  test "create?() returns false with a nil user" do
    context = RequestContext.new(user:        nil,
                                 institution: @element.metadata_profile.institution)
    policy = MetadataProfileElementPolicy.new(context, @element)
    assert !policy.create?
  end

  test "create?() does not authorize non-privileged users" do
    user    = users(:southwest)
    context = RequestContext.new(user:        user,
                                 institution: @element.metadata_profile.institution)
    policy  = MetadataProfileElementPolicy.new(context, @element)
    assert !policy.create?
  end

  test "create?() authorizes administrators of the same institution" do
    user = users(:southwest_admin)
    context = RequestContext.new(user:        user,
                                 institution: @element.metadata_profile.institution)
    policy  = MetadataProfileElementPolicy.new(context, @element)
    assert policy.create?
  end

  test "create?() does not authorize administrators of a different
  institution than in the request context" do
    user    = users(:southwest_admin)
    context = RequestContext.new(user:        user,
                                 institution: institutions(:northeast))
    policy  = MetadataProfileElementPolicy.new(context, @element)
    assert !policy.create?
  end

  test "create?() respects role limits" do
    # sysadmin user limited to an insufficient role
    user    = users(:southwest_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::LOGGED_IN)
    policy  = MetadataProfileElementPolicy.new(context, @element)
    assert !policy.create?
  end

  # destroy?()

  test "destroy?() returns false with a nil user" do
    context = RequestContext.new(user:        nil,
                                 institution: @element.metadata_profile.institution)
    policy = MetadataProfileElementPolicy.new(context, @element)
    assert !policy.destroy?
  end

  test "destroy?() does not authorize an incorrect scope" do
    context = RequestContext.new(user:        users(:southwest_admin),
                                 institution: institutions(:northeast))
    policy  = MetadataProfileElementPolicy.new(context, @element)
    assert !policy.destroy?
  end

  test "destroy?() authorizes sysadmins" do
    @element = metadata_profile_elements(:global_title)
    user     = users(:southwest_sysadmin)
    context  = RequestContext.new(user:        user,
                                  institution: @element.metadata_profile.institution)
    policy   = MetadataProfileElementPolicy.new(context, @element)
    assert policy.destroy?
  end

  test "destroy?() authorizes administrators of the same institution" do
    user    = users(:southwest_admin)
    context = RequestContext.new(user:        user,
                                 institution: @element.metadata_profile.institution)
    policy  = MetadataProfileElementPolicy.new(context, @element)
    assert policy.destroy?
  end

  test "destroy?() does not authorize administrators of a different
  institution than in the request context" do
    user    = users(:southwest_admin)
    context = RequestContext.new(user:        user,
                                 institution: institutions(:northeast))
    policy  = MetadataProfileElementPolicy.new(context, @element)
    assert !policy.destroy?
  end

  test "destroy?() does not authorize administrators of a different
  institution than the metadata profile" do
    user    = users(:northeast_admin)
    context = RequestContext.new(user:        user,
                                 institution: institutions(:northeast))
    policy  = MetadataProfileElementPolicy.new(context, @element)
    assert !policy.destroy?
  end

  test "destroy?() respects role limits" do
    # sysadmin user limited to an insufficient role
    user    = users(:southwest_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::LOGGED_IN)
    policy  = MetadataProfileElementPolicy.new(context, @element)
    assert !policy.destroy?
  end

  # edit?()

  test "edit?() returns false with a nil user" do
    context = RequestContext.new(user:        nil,
                                 institution: @element.metadata_profile.institution)
    policy = MetadataProfileElementPolicy.new(context, @element)
    assert !policy.edit?
  end

  test "edit?() does not authorize an incorrect scope" do
    context = RequestContext.new(user:        users(:southwest_admin),
                                 institution: institutions(:northeast))
    policy  = MetadataProfileElementPolicy.new(context, @element)
    assert !policy.edit?
  end

  test "edit?() does not authorize non-privileged users" do
    user    = users(:southwest)
    context = RequestContext.new(user:        user,
                                 institution: @element.metadata_profile.institution)
    policy  = MetadataProfileElementPolicy.new(context, @element)
    assert !policy.edit?
  end

  test "edit?() authorizes sysadmins" do
    @element = metadata_profile_elements(:global_title)
    user     = users(:southwest_sysadmin)
    context  = RequestContext.new(user:        user,
                                  institution: @element.metadata_profile.institution)
    policy   = MetadataProfileElementPolicy.new(context, @element)
    assert policy.edit?
  end

  test "edit?() authorizes administrators of the same institution" do
    user = users(:southwest_admin)
    context = RequestContext.new(user:        user,
                                 institution: @element.metadata_profile.institution)
    policy  = MetadataProfileElementPolicy.new(context, @element)
    assert policy.edit?
  end

  test "edit?() does not authorize administrators of a different
  institution than in the request context" do
    user    = users(:southwest_admin)
    context = RequestContext.new(user:        user,
                                 institution: institutions(:northeast))
    policy  = MetadataProfileElementPolicy.new(context, @element)
    assert !policy.edit?
  end

  test "edit?() does not authorize administrators of a different
  institution than the metadata profile" do
    user    = users(:northeast_admin)
    context = RequestContext.new(user:        user,
                                 institution: institutions(:northeast))
    policy  = MetadataProfileElementPolicy.new(context, @element)
    assert !policy.edit?
  end

  test "edit?() respects role limits" do
    # sysadmin user limited to an insufficient role
    user    = users(:southwest_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::LOGGED_IN)
    policy  = MetadataProfileElementPolicy.new(context, @element)
    assert !policy.edit?
  end

  # new?()

  test "new?() returns false with a nil user" do
    context = RequestContext.new(user:        nil,
                                 institution: @element.metadata_profile.institution)
    policy = MetadataProfileElementPolicy.new(context, @element)
    assert !policy.new?
  end

  test "new?() does not authorize non-privileged users" do
    user    = users(:southwest)
    context = RequestContext.new(user:        user,
                                 institution: @element.metadata_profile.institution)
    policy  = MetadataProfileElementPolicy.new(context, @element)
    assert !policy.new?
  end

  test "new?() authorizes administrators of the same institution" do
    user = users(:southwest_admin)
    context = RequestContext.new(user:        user,
                                 institution: @element.metadata_profile.institution)
    policy  = MetadataProfileElementPolicy.new(context, @element)
    assert policy.new?
  end

  test "new?() does not authorize administrators of a different
  institution than in the request context" do
    user    = users(:southwest_admin)
    context = RequestContext.new(user:        user,
                                 institution: institutions(:northeast))
    policy  = MetadataProfileElementPolicy.new(context, @element)
    assert !policy.new?
  end

  test "new?() respects role limits" do
    # sysadmin user limited to an insufficient role
    user    = users(:southwest_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::LOGGED_IN)
    policy  = MetadataProfileElementPolicy.new(context, @element)
    assert !policy.new?
  end

  # update?()

  test "update?() returns false with a nil user" do
    context = RequestContext.new(user:        nil,
                                 institution: @element.metadata_profile.institution)
    policy = MetadataProfileElementPolicy.new(context, @element)
    assert !policy.update?
  end

  test "update?() does not authorize an incorrect scope" do
    context = RequestContext.new(user:        users(:southwest_admin),
                                 institution: institutions(:northeast))
    policy  = MetadataProfileElementPolicy.new(context, @element)
    assert !policy.update?
  end

  test "update?() does not authorize non-privileged users" do
    user    = users(:southwest)
    context = RequestContext.new(user:        user,
                                 institution: @element.metadata_profile.institution)
    policy = MetadataProfileElementPolicy.new(context, @element)
    assert !policy.update?
  end

  test "update?() authorizes sysadmins" do
    @element = metadata_profile_elements(:global_title)
    user     = users(:southwest_sysadmin)
    context  = RequestContext.new(user:        user,
                                  institution: @element.metadata_profile.institution)
    policy   = MetadataProfileElementPolicy.new(context, @element)
    assert policy.update?
  end

  test "update?() authorizes administrators of the same institution" do
    user = users(:southwest_admin)
    context = RequestContext.new(user:        user,
                                 institution: @element.metadata_profile.institution)
    policy  = MetadataProfileElementPolicy.new(context, @element)
    assert policy.update?
  end

  test "update?() does not authorize administrators of a different
  institution than in the request context" do
    user    = users(:southwest_admin)
    context = RequestContext.new(user:        user,
                                 institution: institutions(:northeast))
    policy  = MetadataProfileElementPolicy.new(context, @element)
    assert !policy.update?
  end

  test "update?() does not authorize administrators of a different
  institution than the metadata profile" do
    user    = users(:northeast_admin)
    context = RequestContext.new(user:        user,
                                 institution: institutions(:northeast))
    policy  = MetadataProfileElementPolicy.new(context, @element)
    assert !policy.update?
  end

  test "update?() respects role limits" do
    # sysadmin user limited to an insufficient role
    user    = users(:southwest_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::LOGGED_IN)
    policy  = MetadataProfileElementPolicy.new(context, @element)
    assert !policy.update?
  end

end
