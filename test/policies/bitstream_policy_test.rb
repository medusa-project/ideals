require 'test_helper'

class BitstreamPolicyTest < ActiveSupport::TestCase

  class ScopeTest < ActiveSupport::TestCase

    test "resolve() sets no filters for sysadmins" do
      user        = users(:southwest_sysadmin)
      context     = RequestContext.new(user:        user,
                                       institution: user.institution)
      owning_item = items(:southwest_unit1_collection1_item1)
      relation    = owning_item.bitstreams
      count       = relation.count
      scope       = BitstreamPolicy::Scope.new(context, relation, owning_item)
      assert_equal count, scope.resolve.count
    end

    test "resolve() sets filters out non-content bitstreams" do
      user        = users(:southwest)
      context     = RequestContext.new(user:        user,
                                       institution: user.institution)
      owning_item = items(:southwest_unit1_collection1_item1)
      relation    = owning_item.bitstreams
      count       = relation.count
      assert count > 0

      # Assign one of the bitstreams to a non-content bundle, which only
      # collection managers and above are allowed to access.
      relation.first.update!(bundle: Bitstream::Bundle::LICENSE)
      relation = owning_item.bitstreams
      scope    = BitstreamPolicy::Scope.new(context, relation,
                                            owning_item: owning_item)
      assert_equal count - 1, scope.resolve.count
    end

    test "resolve() respects role limits" do
      user        = users(:southwest_admin)
      context     = RequestContext.new(user:        user,
                                       institution: user.institution,
                                       role_limit:  Role::LOGGED_OUT)
      owning_item = items(:southwest_unit1_collection1_item1)
      relation    = owning_item.bitstreams
      count       = relation.count
      assert_equal 1, relation.pluck(:role).select{ |r| r == Role::SYSTEM_ADMINISTRATOR }.length

      scope    = BitstreamPolicy::Scope.new(context, relation,
                                            owning_item: owning_item)
      assert_equal count - 1, scope.resolve.count
    end

  end

  setup do
    @bitstream = bitstreams(:southwest_unit1_collection1_item1_approved)
  end

  # create?()

  test "create?() returns false with a nil user" do
    context = RequestContext.new(user:        nil,
                                 institution: @bitstream.institution)
    policy = BitstreamPolicy.new(context, @bitstream)
    assert !policy.create?
  end

  test "create?() does not authorize an incorrect scope" do
    context = RequestContext.new(user:        users(:southwest_admin),
                                 institution: institutions(:northeast))
    policy  = BitstreamPolicy.new(context, @bitstream)
    assert !policy.create?
  end

  test "create?() is restrictive by default" do
    user    = users(:southwest)
    context = RequestContext.new(user:        user,
                                 institution: @bitstream.institution)
    policy  = BitstreamPolicy.new(context, @bitstream)
    assert !policy.create?
  end

  test "create?() authorizes sysadmins" do
    user    = users(:southwest_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: @bitstream.institution)
    policy  = BitstreamPolicy.new(context, @bitstream)
    assert policy.create?
  end

  test "create?() authorizes unit admins" do
    user    = users(:southwest)
    context = RequestContext.new(user:        user,
                                 institution: @bitstream.institution)

    unit = @bitstream.item.primary_collection.units.first
    unit.administrators.build(user: user)
    unit.save!

    policy = BitstreamPolicy.new(context, @bitstream)
    assert policy.create?
  end

  test "create?() authorizes collection managers" do
    user    = users(:southwest)
    context = RequestContext.new(user:        user,
                                 institution: @bitstream.institution)

    collection = @bitstream.item.primary_collection
    collection.managing_users << user
    collection.save!

    policy = BitstreamPolicy.new(context, @bitstream)
    assert policy.create?
  end

  test "create?() authorizes collection submitters" do
    user    = users(:southwest)
    context = RequestContext.new(user:        user,
                                 institution: @bitstream.institution)

    collection = @bitstream.item.primary_collection
    collection.submitting_users << user
    collection.save!

    policy = BitstreamPolicy.new(context, @bitstream)
    assert policy.create?
  end

  test "create?() respects role limits" do
    # sysadmin user limited to an insufficient role
    user    = users(:southwest_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: @bitstream.institution,
                                 role_limit:  Role::LOGGED_IN)

    policy  = BitstreamPolicy.new(context, @bitstream)
    assert !policy.create?
  end

  # data?()

  test "data?() returns false with a nil user" do
    context = RequestContext.new(user:        nil,
                                 institution: @bitstream.institution)
    policy = BitstreamPolicy.new(context, @bitstream)
    assert !policy.data?
  end

  test "data?() does not authorize an incorrect scope" do
    context = RequestContext.new(user:        users(:southwest_admin),
                                 institution: institutions(:northeast))
    policy  = BitstreamPolicy.new(context, @bitstream)
    assert !policy.data?
  end

  test "data?() is restrictive by default" do
    user    = users(:southwest)
    context = RequestContext.new(user:        user,
                                 institution: @bitstream.institution)
    policy  = BitstreamPolicy.new(context, @bitstream)
    assert !policy.data?
  end

  test "data?() authorizes sysadmins" do
    user    = users(:southwest_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: @bitstream.institution)
    policy  = BitstreamPolicy.new(context, @bitstream)
    assert policy.data?
  end

  test "data?() authorizes unit admins" do
    user    = users(:southwest)
    context = RequestContext.new(user:        user,
                                 institution: @bitstream.institution)

    unit = @bitstream.item.primary_collection.units.first
    unit.administrators.build(user: user)
    unit.save!

    policy = BitstreamPolicy.new(context, @bitstream)
    assert policy.data?
  end

  test "data?() authorizes collection managers" do
    user    = users(:southwest)
    context = RequestContext.new(user:        user,
                                 institution: @bitstream.institution)

    collection = @bitstream.item.primary_collection
    collection.managing_users << user
    collection.save!

    policy = BitstreamPolicy.new(context, @bitstream)
    assert policy.data?
  end

  test "data?() authorizes collection submitters" do
    user    = users(:southwest)
    context = RequestContext.new(user:        user,
                                 institution: @bitstream.institution)

    collection = @bitstream.item.primary_collection
    collection.submitting_users << user
    collection.save!

    policy = BitstreamPolicy.new(context, @bitstream)
    assert policy.data?
  end

  test "data?() respects role limits" do
    # sysadmin user limited to an insufficient role
    user    = users(:southwest_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: @bitstream.institution,
                                 role_limit:  Role::LOGGED_IN)

    policy  = BitstreamPolicy.new(context, @bitstream)
    assert !policy.data?
  end

  # destroy?()

  test "destroy?() returns false with a nil user" do
    context = RequestContext.new(user:        nil,
                                 institution: @bitstream.institution)
    policy = BitstreamPolicy.new(context, @bitstream)
    assert !policy.destroy?
  end

  test "destroy?() authorizes sysadmins" do
    user    = users(:southwest_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: @bitstream.institution)
    policy  = BitstreamPolicy.new(context, @bitstream)
    assert policy.destroy?
  end

  test "destroy?() does not authorize the bitstream owner if the item is not
  submitting" do
    user    = users(:southwest)
    context = RequestContext.new(user:        user,
                                 institution: @bitstream.institution)

    item = @bitstream.item
    item.update!(submitter: user, stage: Item::Stages::APPROVED)

    policy = BitstreamPolicy.new(context, @bitstream)
    assert !policy.destroy?
  end

  test "destroy?() authorizes managers of the bitstream's collection to
  submitting items" do
    doing_user = users(:southwest)
    context    = RequestContext.new(user:        doing_user,
                                    institution: doing_user.institution)
    collection = collections(:southwest_unit1_collection1)
    collection.managing_users << doing_user
    collection.save!

    item = @bitstream.item
    item.update!(submitter:          users(:southwest), # somebody else
                 stage:              Item::Stages::SUBMITTING,
                 primary_collection: collection)

    policy = BitstreamPolicy.new(context, @bitstream)
    assert policy.destroy?
  end

  test "destroy?() does not authorize managers of the bitstream's collection to
  non-submitting items" do
    doing_user = users(:southwest)
    context    = RequestContext.new(user:        doing_user,
                                    institution: doing_user.institution)
    collection = collections(:southwest_unit1_collection1)
    collection.managing_users << doing_user
    collection.save!

    item = @bitstream.item
    item.update!(submitter:          users(:southwest), # somebody else
                 stage:              Item::Stages::APPROVED,
                 primary_collection: collection)

    policy = BitstreamPolicy.new(context, @bitstream)
    assert !policy.destroy?
  end

  test "destroy?() authorizes admins of the submission's collection's unit to
  submitting items" do
    doing_user    = users(:southwest)
    context       = RequestContext.new(user:        doing_user,
                                       institution: doing_user.institution)
    collection               = collections(:southwest_unit1_collection1)
    unit                     = collection.primary_unit
    unit.administering_users << doing_user
    unit.save!

    item = @bitstream.item
    item.update!(submitter:          users(:southwest), # somebody else
                 stage:              Item::Stages::SUBMITTING,
                 primary_collection: collection)

    policy = BitstreamPolicy.new(context, @bitstream)
    assert policy.destroy?
  end

  test "destroy?() does not authorize admins of the submission's collection's
  unit to non-submitting items" do
    doing_user    = users(:southwest)
    context       = RequestContext.new(user:        doing_user,
                                       institution: doing_user.institution)
    collection               = collections(:southwest_unit1_collection1)
    unit                     = collection.primary_unit
    unit.administering_users << doing_user
    unit.save!

    item = @bitstream.item
    item.update!(submitter:          users(:southwest), # somebody else
                 stage:              Item::Stages::APPROVED,
                 primary_collection: collection)

    policy = BitstreamPolicy.new(context, @bitstream)
    assert !policy.destroy?
  end

  test "destroy?() does not authorize anyone else" do
    user    = users(:southwest)
    context = RequestContext.new(user:        user,
                                 institution: @bitstream.institution)
    policy  = BitstreamPolicy.new(context, @bitstream)
    assert !policy.destroy?
  end

  test "destroy?() respects role limits" do
    # sysadmin user limited to an insufficient role
    user    = users(:southwest_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: @bitstream.institution,
                                 role_limit:  Role::COLLECTION_SUBMITTER)
    policy  = BitstreamPolicy.new(context, @bitstream)
    assert !policy.destroy?
  end

  # download?()

  test "download?() returns true with a nil user" do
    context = RequestContext.new(user:        nil,
                                 institution: @bitstream.institution)
    policy = BitstreamPolicy.new(context, @bitstream)
    assert policy.download?
  end

  test "download?() restricts embargoed items by default" do
    user    = users(:southwest)
    context = RequestContext.new(user:        user,
                                 institution: @bitstream.institution)
    policy  = BitstreamPolicy.new(context, bitstreams(:southwest_unit1_collection1_embargoed_1))
    assert !policy.download?
  end

  test "download?() restricts submitting items by default" do
    user    = users(:southwest)
    context = RequestContext.new(user:        user,
                                 institution: @bitstream.institution)
    policy  = BitstreamPolicy.new(context, bitstreams(:southwest_unit1_collection1_submitting_1))
    assert !policy.download?
  end

  test "download?() restricts withdrawn items by default" do
    user    = users(:southwest)
    context = RequestContext.new(user:        user,
                                 institution: @bitstream.institution)
    policy  = BitstreamPolicy.new(context, bitstreams(:southwest_unit1_collection1_withdrawn_1))
    assert !policy.download?
  end

  test "download?() authorizes sysadmins to embargoed items" do
    user    = users(:southwest_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: @bitstream.institution)
    policy  = BitstreamPolicy.new(context, bitstreams(:southwest_unit1_collection1_embargoed_1))
    assert policy.download?
  end

  test "download?() authorizes sysadmins to submitting items" do
    user    = users(:southwest_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: @bitstream.institution)
    policy  = BitstreamPolicy.new(context, bitstreams(:southwest_unit1_collection1_submitting_1))
    assert policy.download?
  end

  test "download?() authorizes sysadmins to withdrawn items" do
    user    = users(:southwest_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: @bitstream.institution)
    policy  = BitstreamPolicy.new(context, bitstreams(:southwest_unit1_collection1_withdrawn_1))
    assert policy.download?
  end

  test "download?() respects role limits" do
    # sysadmin user limited to an insufficient role
    user    = users(:southwest_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: @bitstream.institution,
                                 role_limit:  Role::COLLECTION_SUBMITTER)
    policy  = BitstreamPolicy.new(context, bitstreams(:southwest_unit1_collection1_withdrawn_1))
    assert !policy.download?
  end

  test "download?() respects bitstream role limits" do
    user    = users(:southwest_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: @bitstream.institution,
                                 role_limit:  Role::COLLECTION_SUBMITTER)
    policy  = BitstreamPolicy.new(context, bitstreams(:southwest_unit1_collection1_item1_role_limited))
    assert !policy.download?
  end

  test "download?() restricts non-content bitstreams to non-collection managers" do
    user    = users(:southwest)
    context = RequestContext.new(user:        user,
                                 institution: @bitstream.institution)
    policy  = BitstreamPolicy.new(context, bitstreams(:southwest_unit1_collection1_item1_license))
    assert !policy.download?
  end

  test "download?() restricts bitstreams whose owning items are embargoed" do
    user      = users(:southwest)
    context   = RequestContext.new(user:        user,
                                   institution: @bitstream.institution)
    bitstream = bitstreams(:southwest_unit1_collection1_item1_approved)
    policy    = BitstreamPolicy.new(context, bitstream)

    assert policy.download?
    bitstream.item.embargoes.build(expires_at: Time.now + 1.hour,
                                   kind:       Embargo::Kind::DOWNLOAD).save!
    assert !policy.download?
  end

  test "download?() does not restrict bitstreams whose owning items are
  embargoed when the current user is exempt from all embargoes" do
    user         = users(:southwest)
    group        = user_groups(:southwest_unused)
    group.users << user

    context   = RequestContext.new(user:        user,
                                   institution: @bitstream.institution)
    bitstream = bitstreams(:southwest_unit1_collection1_item1_approved)
    policy    = BitstreamPolicy.new(context, bitstream)
    assert policy.download?

    bitstream.item.embargoes.build(expires_at:  Time.now + 1.hour,
                                   kind:        Embargo::Kind::ALL_ACCESS,
                                   user_groups: [group]).save!
    assert policy.download?
  end

  test "download?() authorizes non-content bitstreams to collection managers" do
    user    = users(:southwest_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: @bitstream.institution)
    policy  = BitstreamPolicy.new(context, bitstreams(:southwest_unit1_collection1_item1_license))
    assert policy.download?
  end

  test "download?() authorizes clients whose hostname or IP matches a user group
  assigned to the bitstream" do
    group     = user_groups(:hostname)
    bitstream = bitstreams(:southwest_unit1_collection1_item1_approved)
    item      = bitstream.item
    item.bitstream_authorizations.build(user_group: group)
    item.save!

    context   = RequestContext.new(client_ip:       "10.0.0.1",
                                   client_hostname: "example.org",
                                   institution:     bitstream.institution)
    policy    = BitstreamPolicy.new(context, bitstream)
    assert policy.download?
  end

  test "download?() does not authorize clients whose hostname or IP does not
  match a user group assigned to the bitstream" do
    group     = user_groups(:hostname)
    bitstream = bitstreams(:southwest_unit1_collection1_item1_approved)
    item      = bitstream.item
    item.bitstream_authorizations.build(user_group: group)
    item.save!

    context   = RequestContext.new(client_ip:       "10.0.0.1",
                                   client_hostname: "something-else.org")
    policy    = BitstreamPolicy.new(context, bitstream)
    assert !policy.download?
  end

  # edit?()

  test "edit?() returns false with a nil user" do
    context = RequestContext.new(user:        nil,
                                 institution: @bitstream.institution)
    policy = BitstreamPolicy.new(context, @bitstream)
    assert !policy.edit?
  end

  test "edit?() is restrictive by default" do
    user    = users(:southwest)
    context = RequestContext.new(user:        user,
                                 institution: @bitstream.institution)
    policy  = BitstreamPolicy.new(context, @bitstream)
    assert !policy.edit?
  end

  test "edit?() authorizes sysadmins" do
    user    = users(:southwest_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: @bitstream.institution)
    policy  = BitstreamPolicy.new(context, @bitstream)
    assert policy.edit?
  end

  test "edit?() authorizes unit admins" do
    user    = users(:southwest)
    context = RequestContext.new(user:        user,
                                 institution: @bitstream.institution)
    unit    = @bitstream.item.primary_collection.units.first
    unit.administrators.build(user: user)
    unit.save!
    policy = BitstreamPolicy.new(context, @bitstream)
    assert policy.edit?
  end

  test "edit?() authorizes collection managers" do
    user    = users(:southwest)
    context = RequestContext.new(user:        user,
                                 institution: @bitstream.institution)
    collection = @bitstream.item.primary_collection
    collection.managers.build(user: user)
    collection.save!
    policy = BitstreamPolicy.new(context, @bitstream)
    assert policy.edit?
  end

  test "edit?() respects role limits" do
    # sysadmin user limited to an insufficient role
    user    = users(:southwest_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: @bitstream.institution,
                                 role_limit:  Role::LOGGED_IN)
    policy  = BitstreamPolicy.new(context, @bitstream)
    assert !policy.edit?
  end

  # index?()

  test "index?() returns true with a nil user" do
    context = RequestContext.new(user:        nil,
                                 institution: @bitstream.institution)
    policy = BitstreamPolicy.new(context, Bitstream)
    assert policy.index?
  end

  test "index?() authorizes everyone" do
    user    = users(:southwest)
    context = RequestContext.new(user:        user,
                                 institution: @bitstream.institution)
    policy  = BitstreamPolicy.new(context, Bitstream)
    assert policy.index?
  end

  # ingest?()

  test "ingest?() returns false with a nil user" do
    context = RequestContext.new(user:        nil,
                                 institution: @bitstream.institution)
    policy = BitstreamPolicy.new(context, @bitstream)
    assert !policy.ingest?
  end

  test "ingest?() is restrictive by default" do
    user    = users(:southwest)
    context = RequestContext.new(user:        user,
                                 institution: @bitstream.institution)
    policy  = BitstreamPolicy.new(context, @bitstream)
    assert !policy.ingest?
  end

  test "ingest?() authorizes sysadmins" do
    user    = users(:southwest_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: @bitstream.institution)
    policy  = BitstreamPolicy.new(context, @bitstream)
    assert policy.ingest?
  end

  test "ingest?() authorizes unit admins" do
    user    = users(:southwest)
    context = RequestContext.new(user:        user,
                                 institution: @bitstream.institution)
    unit    = @bitstream.item.primary_collection.units.first
    unit.administrators.build(user: user)
    unit.save!
    policy = BitstreamPolicy.new(context, @bitstream)
    assert policy.ingest?
  end

  test "ingest?() authorizes collection managers" do
    user    = users(:southwest)
    context = RequestContext.new(user:        user,
                                 institution: @bitstream.institution)
    collection = @bitstream.item.primary_collection
    collection.managers.build(user: user)
    collection.save!
    policy = BitstreamPolicy.new(context, @bitstream)
    assert policy.ingest?
  end

  test "ingest?() respects role limits" do
    # sysadmin user limited to an insufficient role
    user    = users(:southwest_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: @bitstream.institution,
                                 role_limit:  Role::COLLECTION_SUBMITTER)
    policy  = BitstreamPolicy.new(context, @bitstream)
    assert !policy.ingest?
  end

  # object?()

  test "object?() returns true with a nil user" do
    context = RequestContext.new(user:        nil,
                                 institution: @bitstream.institution)
    policy = BitstreamPolicy.new(context, @bitstream)
    assert policy.object?
  end

  test "object?() restricts embargoed items by default" do
    user    = users(:southwest)
    context = RequestContext.new(user:        user,
                                 institution: @bitstream.institution)
    policy  = BitstreamPolicy.new(context, bitstreams(:southwest_unit1_collection1_embargoed_1))
    assert !policy.object?
  end

  test "object?() restricts submitting items by default" do
    user    = users(:southwest)
    context = RequestContext.new(user:        user,
                                 institution: @bitstream.institution)
    policy  = BitstreamPolicy.new(context, bitstreams(:southwest_unit1_collection1_submitting_1))
    assert !policy.object?
  end

  test "object?() restricts withdrawn items by default" do
    user    = users(:southwest)
    context = RequestContext.new(user:        user,
                                 institution: @bitstream.institution)
    policy  = BitstreamPolicy.new(context, bitstreams(:southwest_unit1_collection1_withdrawn_1))
    assert !policy.object?
  end

  test "object?() authorizes sysadmins to embargoed items" do
    user    = users(:southwest_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: @bitstream.institution)
    policy  = BitstreamPolicy.new(context, bitstreams(:southwest_unit1_collection1_embargoed_1))
    assert policy.object?
  end

  test "object?() authorizes sysadmins to submitting items" do
    user    = users(:southwest_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: @bitstream.institution)
    policy  = BitstreamPolicy.new(context, bitstreams(:southwest_unit1_collection1_submitting_1))
    assert policy.object?
  end

  test "object?() authorizes sysadmins to withdrawn items" do
    user    = users(:southwest_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: @bitstream.institution)
    policy  = BitstreamPolicy.new(context, bitstreams(:southwest_unit1_collection1_withdrawn_1))
    assert policy.object?
  end

  test "object?() respects role limits" do
    # sysadmin user limited to an insufficient role
    user    = users(:southwest_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: @bitstream.institution,
                                 role_limit:  Role::COLLECTION_SUBMITTER)
    policy  = BitstreamPolicy.new(context, bitstreams(:southwest_unit1_collection1_withdrawn_1))
    assert !policy.object?
  end

  test "object?() respects bitstream role limits" do
    user    = users(:southwest_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: @bitstream.institution,
                                 role_limit:  Role::COLLECTION_SUBMITTER)
    policy  = BitstreamPolicy.new(context, bitstreams(:southwest_unit1_collection1_item1_role_limited))
    assert !policy.object?
  end

  test "object?() restricts non-content bitstreams to non-collection managers" do
    user    = users(:southwest)
    context = RequestContext.new(user:        user,
                                 institution: @bitstream.institution)
    policy  = BitstreamPolicy.new(context, bitstreams(:southwest_unit1_collection1_item1_license))
    assert !policy.object?
  end

  test "object?() restricts bitstreams whose owning items are embargoed" do
    user      = users(:southwest)
    context   = RequestContext.new(user:        user,
                                   institution: @bitstream.institution)
    bitstream = bitstreams(:southwest_unit1_collection1_item1_approved)
    policy    = BitstreamPolicy.new(context, bitstream)

    assert policy.object?
    bitstream.item.embargoes.build(expires_at: Time.now + 1.hour,
                                   kind:       Embargo::Kind::DOWNLOAD).save!
    assert !policy.object?
  end

  test "object?() does not restrict bitstreams whose owning items are embargoed
  when the current user is exempt from all embargoes" do
    user         = users(:southwest)
    group        = user_groups(:southwest_unused)
    group.users << user

    context   = RequestContext.new(user:        user,
                                   institution: @bitstream.institution)
    bitstream = bitstreams(:southwest_unit1_collection1_item1_approved)
    policy    = BitstreamPolicy.new(context, bitstream)
    assert policy.object?

    bitstream.item.embargoes.build(expires_at:  Time.now + 1.hour,
                                   kind:        Embargo::Kind::ALL_ACCESS,
                                   user_groups: [group]).save!
    assert policy.object?
  end

  test "object?() authorizes non-content bitstreams to collection managers" do
    user    = users(:southwest_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: @bitstream.institution)
    policy  = BitstreamPolicy.new(context, bitstreams(:southwest_unit1_collection1_item1_license))
    assert policy.object?
  end

  # show?()

  test "show?() returns true with a nil user" do
    context = RequestContext.new(user:        nil,
                                 institution: @bitstream.institution)
    policy = BitstreamPolicy.new(context, @bitstream)
    assert policy.show?
  end

  test "show?() restricts embargoed items by default" do
    user    = users(:southwest)
    context = RequestContext.new(user:        user,
                                 institution: @bitstream.institution)
    policy  = BitstreamPolicy.new(context, bitstreams(:southwest_unit1_collection1_embargoed_1))
    assert !policy.show?
  end

  test "show?() restricts submitting items by default" do
    user    = users(:southwest)
    context = RequestContext.new(user:        user,
                                 institution: @bitstream.institution)
    policy  = BitstreamPolicy.new(context, bitstreams(:southwest_unit1_collection1_submitting_1))
    assert !policy.show?
  end

  test "show?() restricts withdrawn items by default" do
    user    = users(:southwest)
    context = RequestContext.new(user:        user,
                                 institution: @bitstream.institution)
    policy  = BitstreamPolicy.new(context, bitstreams(:southwest_unit1_collection1_withdrawn_1))
    assert !policy.show?
  end

  test "show?() authorizes sysadmins to embargoed items" do
    user    = users(:southwest_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: @bitstream.institution)
    policy  = BitstreamPolicy.new(context, bitstreams(:southwest_unit1_collection1_embargoed_1))
    assert policy.show?
  end

  test "show?() authorizes sysadmins to submitting items" do
    user    = users(:southwest_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: @bitstream.institution)
    policy  = BitstreamPolicy.new(context, bitstreams(:southwest_unit1_collection1_submitting_1))
    assert policy.show?
  end

  test "show?() authorizes sysadmins to withdrawn items" do
    user    = users(:southwest_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: @bitstream.institution)
    policy  = BitstreamPolicy.new(context, bitstreams(:southwest_unit1_collection1_withdrawn_1))
    assert policy.show?
  end

  test "show?() respects bitstream role limits" do
    user    = users(:southwest_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: @bitstream.institution,
                                 role_limit:  Role::COLLECTION_SUBMITTER)
    policy  = BitstreamPolicy.new(context, bitstreams(:southwest_unit1_collection1_item1_role_limited))
    assert !policy.show?
  end

  test "show?() authorizes bitstreams limited to the logged-in role to
  logged-in users" do
    user      = users(:southwest_sysadmin)
    bitstream = bitstreams(:southwest_unit1_collection1_item1_role_limited)
    bitstream.update!(role: Role::LOGGED_IN)
    context   = RequestContext.new(user:        user,
                                   institution: @bitstream.institution)
    policy    = BitstreamPolicy.new(context, bitstream)
    assert policy.show?
  end

  test "show?() does not authorize bitstreams limited to the logged-in role to
  logged-out users" do
    bitstream = bitstreams(:southwest_unit1_collection1_item1_role_limited)
    bitstream.update!(role: Role::LOGGED_IN)
    context   = RequestContext.new(user:        nil,
                                   institution: bitstream.institution)
    policy    = BitstreamPolicy.new(context, bitstream)
    assert !policy.show?
  end

  test "show?() authorizes bitstreams limited to the collection submitter role
  to collection submitters" do
    user      = users(:southwest)
    bitstream = bitstreams(:southwest_unit1_collection1_item1_role_limited)
    bitstream.item.primary_collection.submitting_users << user
    bitstream.update!(role: Role::COLLECTION_SUBMITTER)
    context   = RequestContext.new(user:        user,
                                   institution: @bitstream.institution)
    policy    = BitstreamPolicy.new(context, bitstream)
    assert policy.show?
  end

  test "show?() does not authorize bitstreams limited to the collection
  submitter role to non-collection submitters" do
    user      = users(:southwest)
    bitstream = bitstreams(:southwest_unit1_collection1_item1_role_limited)
    bitstream.update!(role: Role::COLLECTION_SUBMITTER)
    context   = RequestContext.new(user:        user,
                                   institution: @bitstream.institution)
    policy    = BitstreamPolicy.new(context, bitstream)
    assert !policy.show?
  end

  test "show?() authorizes bitstreams limited to the collection manager role
  to collection managers" do
    user      = users(:southwest)
    bitstream = bitstreams(:southwest_unit1_collection1_item1_role_limited)
    bitstream.item.primary_collection.managing_users << user
    bitstream.update!(role: Role::COLLECTION_MANAGER)
    context   = RequestContext.new(user:        user,
                                   institution: @bitstream.institution)
    policy    = BitstreamPolicy.new(context, bitstream)
    assert policy.show?
  end

  test "show?() does not authorize bitstreams limited to the collection manager
  role to non-collection submitters" do
    user      = users(:southwest)
    bitstream = bitstreams(:southwest_unit1_collection1_item1_role_limited)
    bitstream.update!(role: Role::COLLECTION_MANAGER)
    context   = RequestContext.new(user:        user,
                                   institution: @bitstream.institution)
    policy    = BitstreamPolicy.new(context, bitstream)
    assert !policy.show?
  end

  test "show?() authorizes bitstreams limited to the unit administrator role
  to unit administrators" do
    user      = users(:southwest)
    bitstream = bitstreams(:southwest_unit1_collection1_item1_role_limited)
    bitstream.item.primary_unit.administering_users << user
    bitstream.update!(role: Role::UNIT_ADMINISTRATOR)
    context   = RequestContext.new(user:        user,
                                   institution: @bitstream.institution)
    policy    = BitstreamPolicy.new(context, bitstream)
    assert policy.show?
  end

  test "show?() does not authorize bitstreams limited to the unit administrator
  role to non-unit administrators" do
    user      = users(:southwest)
    bitstream = bitstreams(:southwest_unit1_collection1_item1_role_limited)
    bitstream.update!(role: Role::UNIT_ADMINISTRATOR)
    context   = RequestContext.new(user:        user,
                                   institution: @bitstream.institution)
    policy    = BitstreamPolicy.new(context, bitstream)
    assert !policy.show?
  end

  test "show?() authorizes bitstreams limited to the institution administrator
  role to institution administrators" do
    user      = users(:southwest)
    bitstream = bitstreams(:southwest_unit1_collection1_item1_role_limited)
    bitstream.item.institution.administering_users << user
    bitstream.update!(role: Role::INSTITUTION_ADMINISTRATOR)
    context   = RequestContext.new(user:        user,
                                   institution: @bitstream.institution)
    policy    = BitstreamPolicy.new(context, bitstream)
    assert policy.show?
  end

  test "show?() does not authorize bitstreams limited to the institution
  administrator role to non-unit administrators" do
    user      = users(:southwest)
    bitstream = bitstreams(:southwest_unit1_collection1_item1_role_limited)
    bitstream.update!(role: Role::INSTITUTION_ADMINISTRATOR)
    context   = RequestContext.new(user:        user,
                                   institution: @bitstream.institution)
    policy    = BitstreamPolicy.new(context, bitstream)
    assert !policy.show?
  end

  test "show?() authorizes bitstreams limited to the system administrator
  role to system administrators" do
    user      = users(:southwest_sysadmin)
    bitstream = bitstreams(:southwest_unit1_collection1_item1_role_limited)
    bitstream.update!(role: Role::SYSTEM_ADMINISTRATOR)
    context   = RequestContext.new(user:        user,
                                   institution: @bitstream.institution)
    policy    = BitstreamPolicy.new(context, bitstream)
    assert policy.show?
  end

  test "show?() does not authorize bitstreams limited to the system
  administrator role to non-system administrators" do
    user      = users(:southwest)
    bitstream = bitstreams(:southwest_unit1_collection1_item1_role_limited)
    bitstream.update!(role: Role::SYSTEM_ADMINISTRATOR)
    context   = RequestContext.new(user:        user,
                                   institution: @bitstream.institution)
    policy    = BitstreamPolicy.new(context, bitstream)
    assert !policy.show?
  end

  test "show?() restricts non-content bitstreams to non-collection managers" do
    user    = users(:southwest)
    context = RequestContext.new(user:        user,
                                 institution: @bitstream.institution)
    policy  = BitstreamPolicy.new(context, bitstreams(:southwest_unit1_collection1_item1_license))
    assert !policy.show?
  end

  test "show?() restricts bitstreams whose owning items are embargoed" do
    user      = users(:southwest)
    context   = RequestContext.new(user:        user,
                                   institution: @bitstream.institution)
    bitstream = bitstreams(:southwest_unit1_collection1_item1_approved)
    policy    = BitstreamPolicy.new(context, bitstream)

    assert policy.show?
    bitstream.item.embargoes.build(expires_at: Time.now + 1.hour,
                                   kind:       Embargo::Kind::DOWNLOAD).save!
    assert !policy.show?
  end

  test "show?() does not restrict bitstreams whose owning items are embargoed
  when the current user is exempt from all embargoes" do
    user         = users(:southwest)
    group        = user_groups(:southwest_unused)
    group.users << user

    context   = RequestContext.new(user:        user,
                                   institution: @bitstream.institution)
    bitstream = bitstreams(:southwest_unit1_collection1_item1_approved)
    policy    = BitstreamPolicy.new(context, bitstream)
    assert policy.show?

    bitstream.item.embargoes.build(expires_at:  Time.now + 1.hour,
                                   kind:        Embargo::Kind::ALL_ACCESS,
                                   user_groups: [group]).save!
    assert policy.show?
  end

  test "show?() authorizes clients whose hostname or IP matches a user group
  assigned to the bitstream" do
    group     = user_groups(:hostname)
    bitstream = bitstreams(:southwest_unit1_collection1_item1_approved)
    item      = bitstream.item
    item.bitstream_authorizations.build(user_group: group)
    item.save!

    context   = RequestContext.new(client_ip:       "10.0.0.1",
                                   client_hostname: "example.org",
                                   institution:     bitstream.institution)
    policy    = BitstreamPolicy.new(context, bitstream)
    assert policy.show?
  end

  test "show?() does not authorize clients whose hostname or IP does not match
  a user group assigned to the bitstream" do
    group     = user_groups(:hostname)
    bitstream = bitstreams(:southwest_unit1_collection1_item1_approved)
    item      = bitstream.item
    item.bitstream_authorizations.build(user_group: group)
    item.save!

    context   = RequestContext.new(client_ip:       "10.0.0.1",
                                   client_hostname: "something-else.org")
    policy    = BitstreamPolicy.new(context, bitstream)
    assert !policy.show?
  end

  test "show?() respects role limits" do
    # sysadmin user limited to an insufficient role
    user    = users(:southwest_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: @bitstream.institution,
                                 role_limit:  Role::COLLECTION_SUBMITTER)
    policy  = BitstreamPolicy.new(context, bitstreams(:southwest_unit1_collection1_withdrawn_1))
    assert !policy.show?
  end

  # show_details?()

  test "show_details?() returns false with a nil user" do
    context = RequestContext.new(user:        nil,
                                 institution: @bitstream.institution)
    policy = BitstreamPolicy.new(context, @bitstream)
    assert !policy.show_details?
  end

  test "show_details?() does not authorize non-sysadmins" do
    user    = users(:southwest)
    context = RequestContext.new(user:        user,
                                 institution: @bitstream.institution)
    policy  = BitstreamPolicy.new(context, @bitstream)
    assert !policy.show_details?
  end

  test "show_details?() authorizes sysadmins" do
    user    = users(:southwest_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: @bitstream.institution)
    policy = BitstreamPolicy.new(context, @bitstream)
    assert policy.show_details?
  end

  test "show_details?() respects role limits" do
    # sysadmin user limited to an insufficient role
    user    = users(:southwest_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: @bitstream.institution,
                                 role_limit:  Role::COLLECTION_SUBMITTER)
    policy  = BitstreamPolicy.new(context, @bitstream)
    assert !policy.show_details?
  end

  # show_role?()

  test "show_role?() returns false with a nil user" do
    context = RequestContext.new(user:        nil,
                                 institution: @bitstream.institution)
    policy = BitstreamPolicy.new(context, @bitstream)
    assert !policy.show_role?
  end

  test "show_role?() is restrictive by default" do
    user    = users(:southwest)
    context = RequestContext.new(user:        user,
                                 institution: @bitstream.institution)
    policy  = BitstreamPolicy.new(context, @bitstream)
    assert !policy.show_role?
  end

  test "show_role?() authorizes sysadmins" do
    user    = users(:southwest_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: @bitstream.institution)
    policy  = BitstreamPolicy.new(context, @bitstream)
    assert policy.show_role?
  end

  test "show_role?() authorizes unit admins" do
    user    = users(:southwest)
    context = RequestContext.new(user:        user,
                                 institution: @bitstream.institution)

    unit = @bitstream.item.primary_collection.units.first
    unit.administrators.build(user: user)
    unit.save!

    policy = BitstreamPolicy.new(context, @bitstream)
    assert policy.show_role?
  end

  test "show_role?() authorizes collection managers" do
    user    = users(:southwest)
    context = RequestContext.new(user:        user,
                                 institution: @bitstream.institution)

    collection = @bitstream.item.primary_collection
    collection.managing_users << user
    collection.save!

    policy = BitstreamPolicy.new(context, @bitstream)
    assert policy.show_role?
  end

  test "show_role?() respects role limits" do
    # sysadmin user limited to an insufficient role
    user    = users(:southwest_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: @bitstream.institution,
                                 role_limit:  Role::LOGGED_IN)

    policy  = BitstreamPolicy.new(context, @bitstream)
    assert !policy.show_role?
  end

  # stream?()

  test "stream?() returns true with a nil user" do
    context = RequestContext.new(user:        nil,
                                 institution: @bitstream.institution)
    policy = BitstreamPolicy.new(context, @bitstream)
    assert policy.stream?
  end

  test "stream?() restricts embargoed items by default" do
    user    = users(:southwest)
    context = RequestContext.new(user:        user,
                                 institution: @bitstream.institution)
    policy  = BitstreamPolicy.new(context, bitstreams(:southwest_unit1_collection1_embargoed_1))
    assert !policy.stream?
  end

  test "stream?() restricts submitting items by default" do
    user    = users(:southwest)
    context = RequestContext.new(user:        user,
                                 institution: @bitstream.institution)
    policy  = BitstreamPolicy.new(context, bitstreams(:southwest_unit1_collection1_submitting_1))
    assert !policy.stream?
  end

  test "stream?() restricts withdrawn items by default" do
    user    = users(:southwest)
    context = RequestContext.new(user:        user,
                                 institution: @bitstream.institution)
    policy  = BitstreamPolicy.new(context, bitstreams(:southwest_unit1_collection1_withdrawn_1))
    assert !policy.stream?
  end

  test "stream?() authorizes sysadmins to embargoed items" do
    user    = users(:southwest_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: @bitstream.institution)
    policy  = BitstreamPolicy.new(context, bitstreams(:southwest_unit1_collection1_embargoed_1))
    assert policy.stream?
  end

  test "stream?() authorizes sysadmins to submitting items" do
    user    = users(:southwest_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: @bitstream.institution)
    policy  = BitstreamPolicy.new(context, bitstreams(:southwest_unit1_collection1_submitting_1))
    assert policy.stream?
  end

  test "stream?() authorizes sysadmins to withdrawn items" do
    user    = users(:southwest_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: @bitstream.institution)
    policy  = BitstreamPolicy.new(context, bitstreams(:southwest_unit1_collection1_withdrawn_1))
    assert policy.stream?
  end

  test "stream?() respects role limits" do
    # sysadmin user limited to an insufficient role
    user    = users(:southwest_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: @bitstream.institution,
                                 role_limit:  Role::COLLECTION_SUBMITTER)
    policy  = BitstreamPolicy.new(context, bitstreams(:southwest_unit1_collection1_withdrawn_1))
    assert !policy.stream?
  end

  test "stream?() respects bitstream role limits" do
    user    = users(:southwest_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: @bitstream.institution,
                                 role_limit:  Role::COLLECTION_SUBMITTER)
    policy  = BitstreamPolicy.new(context, bitstreams(:southwest_unit1_collection1_item1_role_limited))
    assert !policy.stream?
  end

  test "stream?() restricts non-content bitstreams to non-collection managers" do
    user    = users(:southwest)
    context = RequestContext.new(user:        user,
                                 institution: @bitstream.institution)
    policy  = BitstreamPolicy.new(context, bitstreams(:southwest_unit1_collection1_item1_license))
    assert !policy.stream?
  end

  test "stream?() restricts bitstreams whose owning items are embargoed" do
    user      = users(:southwest)
    context   = RequestContext.new(user:        user,
                                   institution: @bitstream.institution)
    bitstream = bitstreams(:southwest_unit1_collection1_item1_approved)
    policy    = BitstreamPolicy.new(context, bitstream)

    assert policy.stream?
    bitstream.item.embargoes.build(expires_at: Time.now + 1.hour,
                                   kind:       Embargo::Kind::DOWNLOAD).save!
    assert !policy.stream?
  end

  test "stream?() does not restrict bitstreams whose owning items are embargoed
  when the current user is exempt from all embargoes" do
    user         = users(:southwest)
    group        = user_groups(:southwest_unused)
    group.users << user

    context   = RequestContext.new(user:        user,
                                   institution: @bitstream.institution)
    bitstream = bitstreams(:southwest_unit1_collection1_item1_approved)
    policy    = BitstreamPolicy.new(context, bitstream)
    assert policy.stream?

    bitstream.item.embargoes.build(expires_at:  Time.now + 1.hour,
                                   kind:        Embargo::Kind::ALL_ACCESS,
                                   user_groups: [group]).save!
    assert policy.stream?
  end

  test "stream?() authorizes non-content bitstreams to collection managers" do
    user    = users(:southwest_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: @bitstream.institution)
    policy  = BitstreamPolicy.new(context, bitstreams(:southwest_unit1_collection1_item1_license))
    assert policy.stream?
  end

  # update?()

  test "update?() returns false with a nil user" do
    context = RequestContext.new(user:        nil,
                                 institution: @bitstream.institution)
    policy = BitstreamPolicy.new(context, @bitstream)
    assert !policy.update?
  end

  test "update?() does not authorize non-sysadmins" do
    user    = users(:southwest)
    context = RequestContext.new(user:        user,
                                 institution: @bitstream.institution)
    policy  = BitstreamPolicy.new(context, @bitstream)
    assert !policy.update?
  end

  test "update?() authorizes sysadmins" do
    user    = users(:southwest_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: @bitstream.institution)
    policy  = BitstreamPolicy.new(context, @bitstream)
    assert policy.update?
  end

  test "update?() does not authorize the submission owner if the item is not submitting" do
    user    = users(:southwest)
    context = RequestContext.new(user:        user,
                                 institution: @bitstream.institution)
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
    doing_user = users(:southwest)
    context    = RequestContext.new(user:        doing_user,
                                    institution: doing_user.institution)
    collection = collections(:uiuc_collection1)
    collection.managing_users << doing_user
    collection.save!

    item = @bitstream.item
    item.update!(submitter:          users(:southwest), # somebody else
                 primary_collection: collection)

    policy = BitstreamPolicy.new(context, @bitstream)
    assert policy.update?
  end

  test "update?() authorizes admins of the submission's collection's unit" do
    doing_user = users(:southwest)
    context    = RequestContext.new(user:        doing_user,
                                    institution: doing_user.institution)
    collection               = collections(:uiuc_collection1)
    unit                     = collection.primary_unit
    unit.administering_users << doing_user
    unit.save!

    item = @bitstream.item
    item.update!(submitter:          users(:southwest), # somebody else
                 primary_collection: collection)

    policy = BitstreamPolicy.new(context, @bitstream)
    assert policy.update?
  end

  test "update?() does not authorize anyone else" do
    user    = users(:southwest)
    context = RequestContext.new(user:        user,
                                 institution: @bitstream.institution)
    policy = BitstreamPolicy.new(context, @bitstream)
    assert !policy.update?
  end

  test "update?() respects role limits" do
    # sysadmin user limited to an insufficient role
    user    = users(:southwest_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: @bitstream.institution,
                                 role_limit:  Role::COLLECTION_SUBMITTER)
    policy  = BitstreamPolicy.new(context, @bitstream)
    assert !policy.update?
  end

  # viewer?()

  test "viewer?() returns true with a nil user" do
    context = RequestContext.new(user:        nil,
                                 institution: @bitstream.institution)
    policy = BitstreamPolicy.new(context, @bitstream)
    assert policy.viewer?
  end

  test "viewer?() restricts embargoed items by default" do
    user    = users(:southwest)
    context = RequestContext.new(user:        user,
                                 institution: @bitstream.institution)
    policy  = BitstreamPolicy.new(context, bitstreams(:southwest_unit1_collection1_embargoed_1))
    assert !policy.viewer?
  end

  test "viewer?() restricts submitting items by default" do
    user    = users(:southwest)
    context = RequestContext.new(user:        user,
                                 institution: @bitstream.institution)
    policy  = BitstreamPolicy.new(context, bitstreams(:southwest_unit1_collection1_submitting_1))
    assert !policy.viewer?
  end

  test "viewer?() restricts withdrawn items by default" do
    user    = users(:southwest)
    context = RequestContext.new(user:        user,
                                 institution: @bitstream.institution)
    policy  = BitstreamPolicy.new(context, bitstreams(:southwest_unit1_collection1_withdrawn_1))
    assert !policy.viewer?
  end

  test "viewer?() authorizes sysadmins to embargoed items" do
    user    = users(:southwest_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: @bitstream.institution)
    policy  = BitstreamPolicy.new(context, bitstreams(:southwest_unit1_collection1_embargoed_1))
    assert policy.viewer?
  end

  test "viewer?() authorizes sysadmins to submitting items" do
    user    = users(:southwest_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: @bitstream.institution)
    policy  = BitstreamPolicy.new(context, bitstreams(:southwest_unit1_collection1_submitting_1))
    assert policy.viewer?
  end

  test "viewer?() authorizes sysadmins to withdrawn items" do
    user    = users(:southwest_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: @bitstream.institution)
    policy  = BitstreamPolicy.new(context, bitstreams(:southwest_unit1_collection1_withdrawn_1))
    assert policy.viewer?
  end

  test "viewer?() respects role limits" do
    # sysadmin user limited to an insufficient role
    user    = users(:southwest_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: @bitstream.institution,
                                 role_limit:  Role::COLLECTION_SUBMITTER)
    policy  = BitstreamPolicy.new(context, bitstreams(:southwest_unit1_collection1_withdrawn_1))
    assert !policy.viewer?
  end

  test "viewer?() respects bitstream role limits" do
    user    = users(:southwest_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: @bitstream.institution,
                                 role_limit:  Role::COLLECTION_SUBMITTER)
    policy  = BitstreamPolicy.new(context, bitstreams(:southwest_unit1_collection1_item1_role_limited))
    assert !policy.viewer?
  end

  test "viewer?() restricts non-content bitstreams to non-collection managers" do
    user    = users(:southwest)
    context = RequestContext.new(user:        user,
                                 institution: @bitstream.institution)
    policy  = BitstreamPolicy.new(context, bitstreams(:southwest_unit1_collection1_item1_license))
    assert !policy.viewer?
  end

  test "viewer?() restricts bitstreams whose owning items are embargoed" do
    user      = users(:southwest)
    context   = RequestContext.new(user:        user,
                                   institution: @bitstream.institution)
    bitstream = bitstreams(:southwest_unit1_collection1_item1_approved)
    policy    = BitstreamPolicy.new(context, bitstream)

    assert policy.viewer?
    bitstream.item.embargoes.build(expires_at: Time.now + 1.hour,
                                   kind:       Embargo::Kind::DOWNLOAD).save!
    assert !policy.viewer?
  end

  test "viewer?() does not restrict bitstreams whose owning items are embargoed
  when the current user is exempt from all embargoes" do
    user         = users(:southwest)
    group        = user_groups(:southwest_unused)
    group.users << user

    bitstream = bitstreams(:southwest_unit1_collection1_embargoed_1)
    item      = bitstream.item
    context   = RequestContext.new(user:        user,
                                   institution: bitstream.institution)
    policy    = BitstreamPolicy.new(context, bitstream)
    assert !policy.viewer?

    item.embargoes.delete_all

    item.embargoes.build(expires_at:  Time.now + 1.hour,
                         kind:        Embargo::Kind::ALL_ACCESS,
                         user_groups: [group]).save!
    item.current_embargoes.reload
    assert policy.viewer?
  end

  test "viewer?() authorizes non-content bitstreams to collection managers" do
    user    = users(:southwest_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: @bitstream.institution)
    policy  = BitstreamPolicy.new(context, bitstreams(:southwest_unit1_collection1_item1_license))
    assert policy.viewer?
  end

  test "viewer?() authorizes clients whose hostname or IP matches a user group
  assigned to the bitstream" do
    group     = user_groups(:hostname)
    bitstream = bitstreams(:southwest_unit1_collection1_item1_approved)
    item      = bitstream.item
    item.bitstream_authorizations.build(user_group: group)
    item.save!

    context   = RequestContext.new(client_ip:       "10.0.0.1",
                                   client_hostname: "example.org",
                                   institution:     bitstream.institution)
    policy    = BitstreamPolicy.new(context, bitstream)
    assert policy.viewer?
  end

  test "viewer?() does not authorize clients whose hostname or IP does not
  match a user group assigned to the bitstream" do
    group     = user_groups(:hostname)
    bitstream = bitstreams(:southwest_unit1_collection1_item1_approved)
    item      = bitstream.item
    item.bitstream_authorizations.build(user_group: group)
    item.save!

    context   = RequestContext.new(client_ip:       "10.0.0.1",
                                   client_hostname: "something-else.org")
    policy    = BitstreamPolicy.new(context, bitstream)
    assert !policy.viewer?
  end

end
