require 'test_helper'

class BitstreamPolicyTest < ActiveSupport::TestCase

  setup do
    @bitstream = bitstreams(:item1_in_staging)
  end

  # create?()

  test "create?() returns false with a nil user" do
    policy = BitstreamPolicy.new(nil, @bitstream)
    assert !policy.create?
  end

  test "create?() is restrictive by default" do
    user    = users(:norights)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::NO_LIMIT)
    policy  = BitstreamPolicy.new(context, @bitstream)
    assert !policy.create?
  end

  test "create?() authorizes sysadmins" do
    user    = users(:local_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::NO_LIMIT)
    policy  = BitstreamPolicy.new(context, @bitstream)
    assert policy.create?
  end

  test "create?() authorizes unit admins" do
    user    = users(:norights)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::NO_LIMIT)

    unit = @bitstream.item.primary_collection.units.first
    unit.administrators.build(user: user)
    unit.save!

    policy = BitstreamPolicy.new(context, @bitstream)
    assert policy.create?
  end

  test "create?() authorizes collection managers" do
    user    = users(:norights)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::NO_LIMIT)

    collection = @bitstream.item.primary_collection
    collection.managing_users << user
    collection.save!

    policy = BitstreamPolicy.new(context, @bitstream)
    assert policy.create?
  end

  test "create?() authorizes collection submitters" do
    user    = users(:norights)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::NO_LIMIT)

    collection = @bitstream.item.primary_collection
    collection.submitting_users << user
    collection.save!

    policy = BitstreamPolicy.new(context, @bitstream)
    assert policy.create?
  end

  test "create?() respects role limits" do
    # sysadmin user limited to an insufficient role
    user    = users(:local_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::LOGGED_IN)

    policy  = BitstreamPolicy.new(context, @bitstream)
    assert !policy.create?
  end

  # data?()

  test "data?() returns true with a nil user" do
    policy = BitstreamPolicy.new(nil, @bitstream)
    assert policy.data?
  end

  test "data?() restricts undiscoverable items by default" do
    user    = users(:norights)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::NO_LIMIT)
    policy  = BitstreamPolicy.new(context, bitstreams(:undiscoverable_in_staging))
    assert !policy.data?
  end

  test "data?() restricts submitting items by default" do
    user    = users(:norights)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::NO_LIMIT)
    policy  = BitstreamPolicy.new(context, bitstreams(:submitting_in_staging))
    assert !policy.data?
  end

  test "data?() restricts withdrawn items by default" do
    user    = users(:norights)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::NO_LIMIT)
    policy  = BitstreamPolicy.new(context, bitstreams(:withdrawn_in_staging))
    assert !policy.data?
  end

  test "data?() authorizes sysadmins to undiscoverable items" do
    user    = users(:local_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::NO_LIMIT)
    policy  = BitstreamPolicy.new(context, bitstreams(:undiscoverable_in_staging))
    assert policy.data?
  end

  test "data?() authorizes sysadmins to submitting items" do
    user    = users(:local_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::NO_LIMIT)
    policy  = BitstreamPolicy.new(context, bitstreams(:submitting_in_staging))
    assert policy.data?
  end

  test "data?() authorizes sysadmins to withdrawn items" do
    user    = users(:local_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::NO_LIMIT)
    policy  = BitstreamPolicy.new(context, bitstreams(:withdrawn_in_staging))
    assert policy.data?
  end

  test "data?() respects role limits" do
    # sysadmin user limited to an insufficient role
    user    = users(:local_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::COLLECTION_SUBMITTER)
    policy  = BitstreamPolicy.new(context, bitstreams(:withdrawn_in_staging))
    assert !policy.data?
  end

  test "data?() respects bitstream role limits" do
    user    = users(:local_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::COLLECTION_SUBMITTER)
    policy  = BitstreamPolicy.new(context, bitstreams(:role_limited))
    assert !policy.data?
  end

  test "data?() restricts non-content bitstreams to non-collection managers" do
    user    = users(:norights)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::NO_LIMIT)
    policy  = BitstreamPolicy.new(context, bitstreams(:license_bundle))
    assert !policy.data?
  end

  test "data?() authorizes non-content bitstreams to collection managers" do
    user    = users(:local_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::NO_LIMIT)
    policy  = BitstreamPolicy.new(context, bitstreams(:license_bundle))
    assert policy.data?
  end

  # destroy?()

  test "destroy?() returns false with a nil user" do
    policy = BitstreamPolicy.new(nil, @bitstream)
    assert !policy.destroy?
  end

  test "destroy?() does not authorize non-sysadmins" do
    user    = users(:norights)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::NO_LIMIT)
    policy  = BitstreamPolicy.new(context, @bitstream)
    assert !policy.destroy?
  end

  test "destroy?() authorizes sysadmins" do
    user    = users(:local_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::NO_LIMIT)
    policy  = BitstreamPolicy.new(context, @bitstream)
    assert policy.destroy?
  end

  test "destroy?() does not authorize the submission owner if the item is not submitting" do
    user    = users(:norights)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::NO_LIMIT)

    item = @bitstream.item
    item.update!(submitter: user, stage: Item::Stages::APPROVED)

    policy = BitstreamPolicy.new(context, @bitstream)
    assert !policy.destroy?
  end

  test "destroy?() authorizes managers of the submission's collection" do
    doing_user = users(:norights)
    context    = RequestContext.new(user:        doing_user,
                                    institution: doing_user.institution,
                                    role_limit:  Role::NO_LIMIT)
    collection = collections(:collection1)
    collection.managing_users << doing_user
    collection.save!

    item = @bitstream.item
    item.update!(submitter:          users(:norights), # somebody else
                 primary_collection: collection)

    policy = BitstreamPolicy.new(context, @bitstream)
    assert policy.destroy?
  end

  test "destroy?() authorizes admins of the submission's collection's unit" do
    doing_user    = users(:norights)
    context       = RequestContext.new(user:        doing_user,
                                       institution: doing_user.institution,
                                       role_limit:  Role::NO_LIMIT)
    collection               = collections(:collection1)
    unit                     = collection.primary_unit
    unit.administering_users << doing_user
    unit.save!

    item = @bitstream.item
    item.update!(submitter: users(:norights), # somebody else
                 primary_collection: collection)

    policy = BitstreamPolicy.new(context, @bitstream)
    assert policy.destroy?
  end

  test "destroy?() does not authorize anyone else" do
    user    = users(:norights)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::NO_LIMIT)
    policy  = BitstreamPolicy.new(context, @bitstream)
    assert !policy.destroy?
  end

  test "destroy?() respects role limits" do
    # sysadmin user limited to an insufficient role
    user    = users(:local_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::COLLECTION_SUBMITTER)
    policy  = BitstreamPolicy.new(context, @bitstream)
    assert !policy.destroy?
  end

  # download?()

  test "download?() returns true with a nil user" do
    policy = BitstreamPolicy.new(nil, @bitstream)
    assert policy.download?
  end

  test "download?() restricts undiscoverable items by default" do
    user    = users(:norights)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::NO_LIMIT)
    policy  = BitstreamPolicy.new(context, bitstreams(:undiscoverable_in_staging))
    assert !policy.download?
  end

  test "download?() restricts submitting items by default" do
    user    = users(:norights)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::NO_LIMIT)
    policy  = BitstreamPolicy.new(context, bitstreams(:submitting_in_staging))
    assert !policy.download?
  end

  test "download?() restricts withdrawn items by default" do
    user    = users(:norights)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::NO_LIMIT)
    policy  = BitstreamPolicy.new(context, bitstreams(:withdrawn_in_staging))
    assert !policy.download?
  end

  test "download?() authorizes sysadmins to undiscoverable items" do
    user    = users(:local_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::NO_LIMIT)
    policy  = BitstreamPolicy.new(context, bitstreams(:undiscoverable_in_staging))
    assert policy.download?
  end

  test "download?() authorizes sysadmins to submitting items" do
    user    = users(:local_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::NO_LIMIT)
    policy  = BitstreamPolicy.new(context, bitstreams(:submitting_in_staging))
    assert policy.download?
  end

  test "download?() authorizes sysadmins to withdrawn items" do
    user    = users(:local_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::NO_LIMIT)
    policy  = BitstreamPolicy.new(context, bitstreams(:withdrawn_in_staging))
    assert policy.download?
  end

  test "download?() respects role limits" do
    # sysadmin user limited to an insufficient role
    user    = users(:local_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::COLLECTION_SUBMITTER)
    policy  = BitstreamPolicy.new(context, bitstreams(:withdrawn_in_staging))
    assert !policy.download?
  end

  test "download?() respects bitstream role limits" do
    user    = users(:local_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::COLLECTION_SUBMITTER)
    policy  = BitstreamPolicy.new(context, bitstreams(:role_limited))
    assert !policy.download?
  end

  test "download?() restricts non-content bitstreams to non-collection managers" do
    user    = users(:norights)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::NO_LIMIT)
    policy  = BitstreamPolicy.new(context, bitstreams(:license_bundle))
    assert !policy.download?
  end

  test "download?() authorizes non-content bitstreams to collection managers" do
    user    = users(:local_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::NO_LIMIT)
    policy  = BitstreamPolicy.new(context, bitstreams(:license_bundle))
    assert policy.download?
  end

  # edit?()

  test "edit?() returns false with a nil user" do
    policy = BitstreamPolicy.new(nil, @bitstream)
    assert !policy.edit?
  end

  test "edit?() is restrictive by default" do
    user    = users(:norights)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::NO_LIMIT)
    policy  = BitstreamPolicy.new(context, @bitstream)
    assert !policy.edit?
  end

  test "edit?() authorizes sysadmins" do
    user    = users(:local_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::NO_LIMIT)
    policy  = BitstreamPolicy.new(context, @bitstream)
    assert policy.edit?
  end

  test "edit?() authorizes unit admins" do
    user    = users(:norights)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::NO_LIMIT)
    unit    = @bitstream.item.primary_collection.units.first
    unit.administrators.build(user: user)
    unit.save!
    policy = BitstreamPolicy.new(context, @bitstream)
    assert policy.edit?
  end

  test "edit?() authorizes collection managers" do
    user    = users(:norights)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::NO_LIMIT)
    collection = @bitstream.item.primary_collection
    collection.managers.build(user: user)
    collection.save!
    policy = BitstreamPolicy.new(context, @bitstream)
    assert policy.edit?
  end

  test "edit?() respects role limits" do
    # sysadmin user limited to an insufficient role
    user    = users(:local_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::LOGGED_IN)
    policy  = BitstreamPolicy.new(context, @bitstream)
    assert !policy.edit?
  end

  # ingest?()

  test "ingest?() returns false with a nil user" do
    policy = BitstreamPolicy.new(nil, @bitstream)
    assert !policy.ingest?
  end

  test "ingest?() is restrictive by default" do
    user    = users(:norights)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::NO_LIMIT)
    policy  = BitstreamPolicy.new(context, @bitstream)
    assert !policy.ingest?
  end

  test "ingest?() authorizes sysadmins" do
    user    = users(:local_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::NO_LIMIT)
    policy  = BitstreamPolicy.new(context, @bitstream)
    assert policy.ingest?
  end

  test "ingest?() authorizes unit admins" do
    user    = users(:norights)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::NO_LIMIT)
    unit    = @bitstream.item.primary_collection.units.first
    unit.administrators.build(user: user)
    unit.save!
    policy = BitstreamPolicy.new(context, @bitstream)
    assert policy.ingest?
  end

  test "ingest?() authorizes collection managers" do
    user    = users(:norights)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::NO_LIMIT)
    collection = @bitstream.item.primary_collection
    collection.managers.build(user: user)
    collection.save!
    policy = BitstreamPolicy.new(context, @bitstream)
    assert policy.ingest?
  end

  test "ingest?() respects role limits" do
    # sysadmin user limited to an insufficient role
    user    = users(:local_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::COLLECTION_SUBMITTER)
    policy  = BitstreamPolicy.new(context, @bitstream)
    assert !policy.ingest?
  end

  # show?()

  test "show?() returns true with a nil user" do
    policy = BitstreamPolicy.new(nil, @bitstream)
    assert policy.show?
  end

  test "show?() restricts undiscoverable items by default" do
    user    = users(:norights)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::NO_LIMIT)
    policy  = BitstreamPolicy.new(context, bitstreams(:undiscoverable_in_staging))
    assert !policy.show?
  end

  test "show?() restricts submitting items by default" do
    user    = users(:norights)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::NO_LIMIT)
    policy  = BitstreamPolicy.new(context, bitstreams(:submitting_in_staging))
    assert !policy.show?
  end

  test "show?() restricts withdrawn items by default" do
    user    = users(:norights)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::NO_LIMIT)
    policy  = BitstreamPolicy.new(context, bitstreams(:withdrawn_in_staging))
    assert !policy.show?
  end

  test "show?() authorizes sysadmins to undiscoverable items" do
    user    = users(:local_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::NO_LIMIT)
    policy  = BitstreamPolicy.new(context, bitstreams(:undiscoverable_in_staging))
    assert policy.show?
  end

  test "show?() authorizes sysadmins to submitting items" do
    user    = users(:local_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::NO_LIMIT)
    policy  = BitstreamPolicy.new(context, bitstreams(:submitting_in_staging))
    assert policy.show?
  end

  test "show?() authorizes sysadmins to withdrawn items" do
    user    = users(:local_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::NO_LIMIT)
    policy  = BitstreamPolicy.new(context, bitstreams(:withdrawn_in_staging))
    assert policy.show?
  end

  test "show?() respects role limits" do
    # sysadmin user limited to an insufficient role
    user    = users(:local_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::COLLECTION_SUBMITTER)
    policy  = BitstreamPolicy.new(context, bitstreams(:withdrawn_in_staging))
    assert !policy.show?
  end

  # update?()

  test "update?() returns false with a nil user" do
    policy = BitstreamPolicy.new(nil, @bitstream)
    assert !policy.update?
  end

  test "update?() does not authorize non-sysadmins" do
    user    = users(:norights)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::NO_LIMIT)
    policy  = BitstreamPolicy.new(context, @bitstream)
    assert !policy.update?
  end

  test "update?() authorizes sysadmins" do
    user    = users(:local_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::NO_LIMIT)
    policy  = BitstreamPolicy.new(context, @bitstream)
    assert policy.update?
  end

  test "update?() does not authorize the submission owner if the item is not submitting" do
    user    = users(:norights)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::NO_LIMIT)
    collection = @bitstream.item.primary_collection
    collection.submitting_users << user
    collection.save!

    item = @bitstream.item
    item.update!(submitter: user,
                 stage: Item::Stages::APPROVED)

    policy = BitstreamPolicy.new(context, @bitstream)
    assert !policy.update?
  end

  test "update?() authorizes managers of the submission's collection" do
    doing_user = users(:norights)
    context    = RequestContext.new(user:        doing_user,
                                    institution: doing_user.institution,
                                    role_limit:  Role::NO_LIMIT)
    collection = collections(:collection1)
    collection.managing_users << doing_user
    collection.save!

    item = @bitstream.item
    item.update!(submitter:          users(:norights), # somebody else
                 primary_collection: collection)

    policy = BitstreamPolicy.new(context, @bitstream)
    assert policy.update?
  end

  test "update?() authorizes admins of the submission's collection's unit" do
    doing_user = users(:norights)
    context    = RequestContext.new(user:        doing_user,
                                    institution: doing_user.institution,
                                    role_limit:  Role::NO_LIMIT)
    collection               = collections(:collection1)
    unit                     = collection.primary_unit
    unit.administering_users << doing_user
    unit.save!

    item = @bitstream.item
    item.update!(submitter:          users(:norights), # somebody else
                 primary_collection: collection)

    policy = BitstreamPolicy.new(context, @bitstream)
    assert policy.update?
  end

  test "update?() does not authorize anyone else" do
    user    = users(:norights)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::NO_LIMIT)
    policy = BitstreamPolicy.new(context, @bitstream)
    assert !policy.update?
  end

  test "update?() respects role limits" do
    # sysadmin user limited to an insufficient role
    user    = users(:local_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::COLLECTION_SUBMITTER)
    policy  = BitstreamPolicy.new(context, @bitstream)
    assert !policy.update?
  end

end
