require 'test_helper'

class MetadataProfileElementPolicyTest < ActiveSupport::TestCase

  setup do
    @element = metadata_profile_elements(:uiuc_default_title)
  end

  # create?()

  test "create?() returns false with a nil user" do
    policy = MetadataProfileElementPolicy.new(nil, @element)
    assert !policy.create?
  end

  test "create?() does not authorize non-privileged users" do
    user    = users(:example)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = MetadataProfileElementPolicy.new(context, @element)
    assert !policy.create?
  end

  test "create?() authorizes administrators of the same institution" do
    user = users(:southwest_admin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
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
    user    = users(:example_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::LOGGED_IN)
    policy  = MetadataProfileElementPolicy.new(context, @element)
    assert !policy.create?
  end

  # destroy?()

  test "destroy?() returns false with a nil user" do
    policy = MetadataProfileElementPolicy.new(nil, @element)
    assert !policy.destroy?
  end

  test "destroy?() authorizes sysadmins to the global profile" do
    @profile = metadata_profiles(:global)
    @element = metadata_profile_elements(:global_title)
    user     = users(:example_sysadmin)
    context  = RequestContext.new(user:        user,
                                  institution: user.institution)
    policy   = MetadataProfileElementPolicy.new(context, @element)
    assert policy.destroy?
  end

  test "destroy?() authorizes administrators of the same institution" do
    user    = users(:uiuc_admin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
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
    user    = users(:example_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::LOGGED_IN)
    policy  = MetadataProfileElementPolicy.new(context, @element)
    assert !policy.destroy?
  end

  # edit?()

  test "edit?() returns false with a nil user" do
    policy = MetadataProfileElementPolicy.new(nil, @element)
    assert !policy.edit?
  end

  test "edit?() does not authorize non-privileged users" do
    user    = users(:example)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = MetadataProfileElementPolicy.new(context, @element)
    assert !policy.edit?
  end

  test "edit?() authorizes sysadmins to the global profile" do
    @profile = metadata_profiles(:global)
    @element = metadata_profile_elements(:global_title)
    user     = users(:example_sysadmin)
    context  = RequestContext.new(user:        user,
                                  institution: user.institution)
    policy   = MetadataProfileElementPolicy.new(context, @element)
    assert policy.edit?
  end

  test "edit?() authorizes administrators of the same institution" do
    user = users(:uiuc_admin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
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
    user    = users(:example_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::LOGGED_IN)
    policy  = MetadataProfileElementPolicy.new(context, @element)
    assert !policy.edit?
  end

  # update?()

  test "update?() returns false with a nil user" do
    policy = MetadataProfileElementPolicy.new(nil, @element)
    assert !policy.update?
  end

  test "update?() does not authorize non-privileged users" do
    user    = users(:example)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy = MetadataProfileElementPolicy.new(context, @element)
    assert !policy.update?
  end

  test "update?() authorizes sysadmins to the global profile" do
    @profile = metadata_profiles(:global)
    @element = metadata_profile_elements(:global_title)
    user     = users(:example_sysadmin)
    context  = RequestContext.new(user:        user,
                                  institution: user.institution)
    policy   = MetadataProfileElementPolicy.new(context, @element)
    assert policy.update?
  end

  test "update?() authorizes administrators of the same institution" do
    user = users(:uiuc_admin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
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
    user    = users(:example_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::LOGGED_IN)
    policy  = MetadataProfileElementPolicy.new(context, @element)
    assert !policy.update?
  end

end