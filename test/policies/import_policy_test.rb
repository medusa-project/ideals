require 'test_helper'

class ImportPolicyTest < ActiveSupport::TestCase

  setup do
    @import = imports(:southwest_saf_new)
  end

  # create?()

  test "create?() returns false with a nil user" do
    context = RequestContext.new(user:        nil,
                                 institution: @import.institution)
    policy = ImportPolicy.new(context, @import)
    assert !policy.create?
  end

  test "create?() is restrictive by default" do
    user    = users(:southwest)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = ImportPolicy.new(context, @import)
    assert !policy.create?
  end

  test "create?() authorizes sysadmins" do
    user    = users(:southwest_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = ImportPolicy.new(context, @import)
    assert policy.create?
  end

  test "create?() authorizes administrators of the same institution" do
    user    = users(:southwest_admin)
    import  = Import.new(user:        user,
                         institution: user.institution,
                         collection:  collections(:uiuc_collection1),
                         format:      Import::Format::CSV_FILE)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = ImportPolicy.new(context, import)
    assert policy.create?
  end

  test "create?() does not authorize administrators of a different
  institution" do
    user    = users(:southwest_admin)
    context = RequestContext.new(user:        user,
                                 institution: institutions(:northeast))
    policy  = ImportPolicy.new(context, @import)
    assert !policy.create?
  end

  test "create?() works with class objects" do
    user    = users(:southwest)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = ImportPolicy.new(context, Import)
    assert !policy.create?
  end

  test "create?() respects role limits" do
    # sysadmin user limited to an insufficient role
    user    = users(:southwest_admin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::COLLECTION_SUBMITTER)
    policy  = ImportPolicy.new(context, @import)
    assert !policy.create?
  end

  # edit?()

  test "edit?() returns false with a nil user" do
    context = RequestContext.new(user:        nil,
                                 institution: @import.institution)
    policy = ImportPolicy.new(context, @import)
    assert !policy.edit?
  end

  test "edit?() does not authorize an incorrect scope" do
    context = RequestContext.new(user:        users(:southwest_admin),
                                 institution: institutions(:northeast))
    policy  = ImportPolicy.new(context, @import)
    assert !policy.edit?
  end

  test "edit?() does not authorize non-privileged users" do
    user    = users(:southwest)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = ImportPolicy.new(context, @import)
    assert !policy.edit?
  end

  test "edit?() does not authorize users other than the one who created the
  instance" do
    user    = users(:southwest)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = ImportPolicy.new(context, @import)
    assert !policy.edit?
  end

  test "edit?() authorizes administrators of the same institution" do
    user    = users(:southwest_admin)
    import  = Import.new(user:        user,
                         institution: user.institution,
                         collection:  collections(:uiuc_collection1),
                         format:      Import::Format::CSV_FILE)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = ImportPolicy.new(context, import)
    assert policy.edit?
  end

  test "edit?() does not authorize administrators of a different
  institution than in the request context" do
    user    = users(:southwest_admin)
    context = RequestContext.new(user:        user,
                                 institution: institutions(:northeast))
    policy  = ImportPolicy.new(context, @import)
    assert !policy.edit?
  end

  test "edit?() does not authorize administrators of a different
  institution than the import" do
    user    = users(:northeast_admin)
    context = RequestContext.new(user:        user,
                                 institution: institutions(:northeast))
    policy  = ImportPolicy.new(context, @import)
    assert !policy.edit?
  end

  test "edit?() authorizes sysadmins" do
    user    = make_sysadmin(@import.user)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = ImportPolicy.new(context, @import)
    assert policy.edit?
  end

  test "edit?() respects role limits" do
    # sysadmin user limited to an insufficient role
    user    = users(:southwest_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::COLLECTION_SUBMITTER)
    policy  = ImportPolicy.new(context, @import)
    assert !policy.edit?
  end

  # index?()

  test "index?() returns false with a nil user" do
    context = RequestContext.new(user:        nil,
                                 institution: @import.institution)
    policy = ImportPolicy.new(context, Import)
    assert !policy.index?
  end

  test "index?() is restrictive by default" do
    user    = users(:southwest)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = ImportPolicy.new(context, @import)
    assert !policy.index?
  end

  test "index?() authorizes sysadmins" do
    user    = users(:southwest_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = ImportPolicy.new(context, @import)
    assert policy.index?
  end

  test "index?() authorizes administrators of the same institution" do
    user    = users(:southwest_admin)
    import  = Import.new(user:        user,
                         institution: user.institution,
                         collection:  collections(:uiuc_collection1),
                         format:      Import::Format::CSV_FILE)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = ImportPolicy.new(context, import)
    assert policy.index?
  end

  test "index?() does not authorize administrators of a different
  institution" do
    user    = users(:southwest_admin)
    context = RequestContext.new(user:        user,
                                 institution: institutions(:northeast))
    policy  = ImportPolicy.new(context, @import)
    assert !policy.index?
  end

  test "index?() respects role limits" do
    # sysadmin user limited to an insufficient role
    user    = users(:southwest_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::COLLECTION_SUBMITTER)
    policy  = ImportPolicy.new(context, @import)
    assert !policy.index?
  end

  # new?()

  test "new?() returns false with a nil user" do
    context = RequestContext.new(user:        nil,
                                 institution: @import.institution)
    policy = ImportPolicy.new(context, @import)
    assert !policy.new?
  end

  test "new?() does not authorize an incorrect scope" do
    context = RequestContext.new(user:        users(:southwest_admin),
                                 institution: institutions(:northeast))
    policy  = ImportPolicy.new(context, @import)
    assert !policy.new?
  end

  test "new?() is restrictive by default" do
    user    = users(:southwest)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = ImportPolicy.new(context, @import)
    assert !policy.new?
  end

  test "new?() authorizes sysadmins" do
    user    = users(:southwest_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = ImportPolicy.new(context, @import)
    assert policy.new?
  end

  test "new?() authorizes administrators of the same institution" do
    user    = users(:southwest_admin)
    import  = Import.new(user:        user,
                         institution: user.institution,
                         collection:  collections(:uiuc_collection1),
                         format:      Import::Format::CSV_FILE)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = ImportPolicy.new(context, import)
    assert policy.new?
  end

  test "new?() does not authorize administrators of a different
  institution" do
    user    = users(:southwest_admin)
    context = RequestContext.new(user:        user,
                                 institution: institutions(:northeast))
    policy  = ImportPolicy.new(context, @import)
    assert !policy.new?
  end

  test "new?() works with class objects" do
    user    = users(:southwest)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = ImportPolicy.new(context, Collection)
    assert !policy.new?
  end

  test "new?() respects role limits" do
    # sysadmin user limited to an insufficient role
    user    = users(:southwest_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::COLLECTION_SUBMITTER)
    policy  = ImportPolicy.new(context, @import)
    assert !policy.new?
  end

  # show?()

  test "show?() returns false with a nil user" do
    context = RequestContext.new(user:        nil,
                                 institution: @import.institution)
    policy = ImportPolicy.new(context, @import)
    assert !policy.show?
  end

  test "show?() does not authorize an incorrect scope" do
    context = RequestContext.new(user:        users(:southwest_admin),
                                 institution: institutions(:northeast))
    policy  = ImportPolicy.new(context, @import)
    assert !policy.show?
  end

  test "show?() does not authorize non-privileged users" do
    user    = users(:southwest)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy = ImportPolicy.new(context, @import)
    assert !policy.show?
  end

  test "show?() authorizes administrators of the same institution" do
    user = users(:southwest_admin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = ImportPolicy.new(context, @import)
    assert policy.show?
  end

  test "show?() does not authorize administrators of a different
  institution than in the request context" do
    user    = users(:southwest_admin)
    context = RequestContext.new(user:        user,
                                 institution: institutions(:northeast))
    policy  = ImportPolicy.new(context, @import)
    assert !policy.show?
  end

  test "show?() does not authorize administrators of a different
  institution than the metadata profile" do
    user    = users(:northeast_admin)
    context = RequestContext.new(user:        user,
                                 institution: institutions(:northeast))
    policy  = ImportPolicy.new(context, @import)
    assert !policy.show?
  end

  test "show?() respects role limits" do
    # sysadmin user limited to an insufficient role
    user    = users(:southwest_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::COLLECTION_SUBMITTER)
    policy  = ImportPolicy.new(context, @import)
    assert !policy.show?
  end

  # upload_file?()

  test "upload_file?() returns false with a nil user" do
    context = RequestContext.new(user:        nil,
                                 institution: @import.institution)
    policy  = ImportPolicy.new(context, @import)
    assert !policy.upload_file?
  end

  test "upload_file?() does not authorize an incorrect scope" do
    context = RequestContext.new(user:        users(:southwest_admin),
                                 institution: institutions(:northeast))
    policy  = ImportPolicy.new(context, @import)
    assert !policy.upload_file?
  end

  test "upload_file?() does not authorize non-privileged users" do
    user    = users(:southwest)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = ImportPolicy.new(context, @import)
    assert !policy.upload_file?
  end

  test "upload_file?() authorizes administrators of the same institution" do
    user = users(:southwest_admin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = ImportPolicy.new(context, @import)
    assert policy.upload_file?
  end

  test "upload_file?() does not authorize users other than the creator of the
  instance" do
    user    = users(:southwest)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = ImportPolicy.new(context, @import)
    assert !policy.upload_file?
  end

  test "upload_file?() authorizes sysadmins" do
    user    = make_sysadmin(@import.user)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = ImportPolicy.new(context, @import)
    assert policy.upload_file?
  end

  test "upload_file?() does not authorize administrators of a different
  institution than in the request context" do
    user    = users(:southwest_admin)
    context = RequestContext.new(user:        user,
                                 institution: institutions(:northeast))
    policy  = ImportPolicy.new(context, @import)
    assert !policy.upload_file?
  end

  test "upload_file?() does not authorize administrators of a different
  institution than the instance" do
    user    = users(:northeast_admin)
    context = RequestContext.new(user:        user,
                                 institution: institutions(:northeast))
    policy  = ImportPolicy.new(context, @import)
    assert !policy.upload_file?
  end

  test "upload_file?() respects role limits" do
    # sysadmin user limited to an insufficient role
    user    = users(:southwest_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::COLLECTION_SUBMITTER)
    policy  = ImportPolicy.new(context, @import)
    assert !policy.upload_file?
  end

end
