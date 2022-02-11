require 'test_helper'

class ImportPolicyTest < ActiveSupport::TestCase

  setup do
    @import = imports(:saf_new)
  end

  # create?

  test "create?() returns false with a nil user" do
    policy = ImportPolicy.new(nil, @import)
    assert !policy.create?
  end

  test "create?() is restrictive by default" do
    user    = users(:norights)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = ImportPolicy.new(context, @import)
    assert !policy.create?
  end

  test "create?() authorizes sysadmins" do
    user    = users(:uiuc_admin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = ImportPolicy.new(context, @import)
    assert policy.create?
  end

  test "create?() works with class objects" do
    user    = users(:norights)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = ImportPolicy.new(context, Import)
    assert !policy.create?
  end

  test "create?() respects role limits" do
    # sysadmin user limited to an insufficient role
    user    = users(:uiuc_admin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::COLLECTION_SUBMITTER)
    policy  = ImportPolicy.new(context, @import)
    assert !policy.create?
  end

  # delete_all_files?()

  test "delete_all_files?() returns false with a nil user" do
    policy = ImportPolicy.new(nil, @import)
    assert !policy.delete_all_files?
  end

  test "delete_all_files?() is restrictive by default" do
    user    = users(:norights)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = ImportPolicy.new(context, @import)
    assert !policy.delete_all_files?
  end

  test "delete_all_files?() authorizes sysadmins" do
    user    = users(:uiuc_admin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = ImportPolicy.new(context, @import)
    assert policy.delete_all_files?
  end

  test "delete_all_files?() respects role limits" do
    # sysadmin user limited to an insufficient role
    user    = users(:uiuc_admin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::COLLECTION_SUBMITTER)
    policy  = ImportPolicy.new(context, @import)
    assert !policy.delete_all_files?
  end

  # edit?()

  test "edit?() returns false with a nil user" do
    policy = ImportPolicy.new(nil, @import)
    assert !policy.edit?
  end

  test "edit?() is restrictive by default" do
    user    = users(:norights)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = ImportPolicy.new(context, @import)
    assert !policy.edit?
  end

  test "edit?() does not authorize users other than the one who created the
  instance" do
    user    = users(:local_sysadmin) # instance was created by uiuc_admin
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = ImportPolicy.new(context, @import)
    assert !policy.edit?
  end

  test "edit?() authorizes sysadmins" do
    user    = users(:uiuc_admin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = ImportPolicy.new(context, @import)
    assert policy.edit?
  end

  test "edit?() respects role limits" do
    # sysadmin user limited to an insufficient role
    user    = users(:uiuc_admin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::COLLECTION_SUBMITTER)
    policy  = ImportPolicy.new(context, @import)
    assert !policy.edit?
  end

  # index?()

  test "index?() returns false with a nil user" do
    policy = ImportPolicy.new(nil, Import)
    assert !policy.index?
  end

  test "index?() is restrictive by default" do
    user    = users(:norights)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = ImportPolicy.new(context, @import)
    assert !policy.index?
  end

  test "index?() authorizes sysadmins" do
    user    = users(:uiuc_admin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = ImportPolicy.new(context, @import)
    assert policy.index?
  end

  test "index?() respects role limits" do
    # sysadmin user limited to an insufficient role
    user    = users(:uiuc_admin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::COLLECTION_SUBMITTER)
    policy  = ImportPolicy.new(context, @import)
    assert !policy.index?
  end

  # new?()

  test "new?() returns false with a nil user" do
    policy = ImportPolicy.new(nil, @import)
    assert !policy.new?
  end

  test "new?() is restrictive by default" do
    user    = users(:norights)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = ImportPolicy.new(context, @import)
    assert !policy.new?
  end

  test "new?() authorizes sysadmins" do
    user    = users(:uiuc_admin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = ImportPolicy.new(context, @import)
    assert policy.new?
  end

  test "new?() works with class objects" do
    user    = users(:norights)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = ImportPolicy.new(context, Collection)
    assert !policy.new?
  end

  test "new?() respects role limits" do
    # sysadmin user limited to an insufficient role
    user    = users(:uiuc_admin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::COLLECTION_SUBMITTER)
    policy  = ImportPolicy.new(context, @import)
    assert !policy.new?
  end

  # show?()

  test "show?() returns false with a nil user" do
    policy = ImportPolicy.new(nil, @import)
    assert !policy.show?
  end

  test "show?() is restrictive by default" do
    user    = users(:norights)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = ImportPolicy.new(context, @import)
    assert !policy.show?
  end

  test "show?() authorizes sysadmins" do
    user    = users(:uiuc_admin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = ImportPolicy.new(context, @import)
    assert policy.show?
  end

  test "show?() works with class objects" do
    user    = users(:norights)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = ImportPolicy.new(context, Collection)
    assert !policy.show?
  end

  test "show?() respects role limits" do
    # sysadmin user limited to an insufficient role
    user    = users(:uiuc_admin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::COLLECTION_SUBMITTER)
    policy  = ImportPolicy.new(context, @import)
    assert !policy.show?
  end

  # update?()

  test "update?() returns false with a nil user" do
    policy = ImportPolicy.new(nil, @import)
    assert !policy.update?
  end

  test "update?() is restrictive by default" do
    user    = users(:norights)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = ImportPolicy.new(context, @import)
    assert !policy.update?
  end

  test "update?() does not authorize users other than the one who created the
  instance" do
    user    = users(:local_sysadmin) # instance was created by uiuc_admin
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = ImportPolicy.new(context, @import)
    assert !policy.update?
  end

  test "update?() authorizes sysadmins" do
    user    = users(:uiuc_admin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = ImportPolicy.new(context, @import)
    assert policy.update?
  end

  test "update?() respects role limits" do
    # sysadmin user limited to an insufficient role
    user    = users(:uiuc_admin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::COLLECTION_SUBMITTER)
    policy  = ImportPolicy.new(context, @import)
    assert !policy.update?
  end

  # upload_file?()

  test "upload_file?() returns false with a nil user" do
    policy = ImportPolicy.new(nil, @import)
    assert !policy.upload_file?
  end

  test "upload_file?() is restrictive by default" do
    user    = users(:norights)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = ImportPolicy.new(context, @import)
    assert !policy.upload_file?
  end

  test "upload_file?() does not authorize users other than the one who created the
  instance" do
    user    = users(:local_sysadmin) # instance was created by uiuc_admin
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = ImportPolicy.new(context, @import)
    assert !policy.upload_file?
  end

  test "upload_file?() authorizes sysadmins" do
    user    = users(:uiuc_admin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = ImportPolicy.new(context, @import)
    assert policy.upload_file?
  end

  test "upload_file?() respects role limits" do
    # sysadmin user limited to an insufficient role
    user    = users(:uiuc_admin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::COLLECTION_SUBMITTER)
    policy  = ImportPolicy.new(context, @import)
    assert !policy.upload_file?
  end

end
