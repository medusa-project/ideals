require 'test_helper'

class SubmissionPolicyTest < ActiveSupport::TestCase

  setup do
    @item = items(:item1)
  end

  # complete?()

  test "complete?() returns false with a nil user" do
    policy = SubmissionPolicy.new(nil, @item)
    assert !policy.complete?
  end

  test "complete?() does not authorize non-sysadmins" do
    user    = users(:norights)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = SubmissionPolicy.new(context, @item)
    assert !policy.complete?
  end

  test "complete?() authorizes sysadmins" do
    user    = users(:local_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy = SubmissionPolicy.new(context, @item)
    assert policy.complete?
  end

  test "complete?() authorizes the submission owner if the item is submitting" do
    user    = users(:norights)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    @item.submitter = user
    @item.stage     = Item::Stages::SUBMITTING
    policy = SubmissionPolicy.new(context, @item)
    assert policy.complete?
  end

  test "complete?() does not authorize the submission owner if the item is not submitting" do
    user    = users(:norights)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    @item.submitter = user
    @item.stage     = Item::Stages::APPROVED
    policy = SubmissionPolicy.new(context, @item)
    assert !policy.complete?
  end

  test "complete?() authorizes managers of the item's collection" do
    doing_user = users(:norights)
    context    = RequestContext.new(user:        doing_user,
                                    institution: doing_user.institution)
    collection = collections(:uiuc_collection1)
    collection.managing_users << doing_user
    collection.save!
    @item.submitter          = users(:norights) # somebody else
    @item.primary_collection = collection

    policy = SubmissionPolicy.new(context, @item)
    assert policy.complete?
  end

  test "complete?() authorizes admins of the item's collection's unit" do
    doing_user = users(:norights)
    context    = RequestContext.new(user:        doing_user,
                                    institution: doing_user.institution)
    collection               = collections(:uiuc_collection1)
    unit                     = collection.primary_unit
    unit.administering_users << doing_user
    unit.save!
    @item.submitter          = users(:norights) # somebody else
    @item.primary_collection = collection

    policy = SubmissionPolicy.new(context, @item)
    assert policy.complete?
  end

  test "complete?() does not authorize anyone else" do
    user    = users(:norights)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = SubmissionPolicy.new(context, @item)
    assert !policy.complete?
  end

  test "complete?() respects role limits" do
    # sysadmin user limited to an insufficient role
    user    = users(:local_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::LOGGED_IN)
    policy  = SubmissionPolicy.new(context, @item)
    assert !policy.complete?
  end

  # destroy?()

  test "destroy?() returns false with a nil user" do
    policy = SubmissionPolicy.new(nil, @item)
    assert !policy.destroy?
  end

  test "destroy?() does not authorize non-sysadmins" do
    user    = users(:norights)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy = SubmissionPolicy.new(context, @item)
    assert !policy.destroy?
  end

  test "destroy?() authorizes sysadmins" do
    user    = users(:local_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy = SubmissionPolicy.new(context, @item)
    assert policy.destroy?
  end

  test "destroy?() authorizes the submission owner if the item is submitting" do
    user    = users(:norights)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    @item.submitter = user
    @item.stage     = Item::Stages::SUBMITTING
    policy = SubmissionPolicy.new(context, @item)
    assert policy.destroy?
  end

  test "destroy?() does not authorize the submission owner if the item is not submitting" do
    user    = users(:norights)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    @item.submitter = user
    @item.stage     = Item::Stages::APPROVED
    policy = SubmissionPolicy.new(context, @item)
    assert !policy.destroy?
  end

  test "destroy?() authorizes managers of the submission's collection" do
    doing_user = users(:norights)
    context    = RequestContext.new(user:        doing_user,
                                    institution: doing_user.institution)
    collection = collections(:uiuc_collection1)
    collection.managing_users << doing_user
    collection.save!
    @item.submitter          = users(:norights) # somebody else
    @item.primary_collection = collection

    policy = SubmissionPolicy.new(context, @item)
    assert policy.destroy?
  end

  test "destroy?() authorizes admins of the submission's collection's unit" do
    doing_user = users(:norights)
    context    = RequestContext.new(user:        doing_user,
                                    institution: doing_user.institution)
    collection               = collections(:uiuc_collection1)
    unit                     = collection.primary_unit
    unit.administering_users << doing_user
    unit.save!
    @item.submitter          = users(:norights) # somebody else
    @item.primary_collection = collection

    policy = SubmissionPolicy.new(context, @item)
    assert policy.destroy?
  end

  test "destroy?() does not authorize anyone else" do
    user    = users(:norights)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = SubmissionPolicy.new(context, @item)
    assert !policy.destroy?
  end

  test "destroy?() respects role limits" do
    # sysadmin user limited to an insufficient role
    user    = users(:local_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::LOGGED_IN)
    policy  = SubmissionPolicy.new(context, @item)
    assert !policy.destroy?
  end

  # edit?()

  test "edit?() returns false with a nil user" do
    policy = SubmissionPolicy.new(nil, @item)
    assert !policy.edit?
  end

  test "edit?() does not authorize non-sysadmins" do
    user    = users(:norights)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = SubmissionPolicy.new(context, @item)
    assert !policy.edit?
  end

  test "edit?() authorizes sysadmins" do
    user    = users(:local_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy = SubmissionPolicy.new(context, @item)
    assert policy.edit?
  end

  test "edit?() authorizes the submission owner if the item is submitting" do
    user    = users(:norights)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    @item.submitter = user
    @item.stage     = Item::Stages::SUBMITTING
    policy = SubmissionPolicy.new(context, @item)
    assert policy.edit?
  end

  test "edit?() does not authorize the submission owner if the item is not submitting" do
    user    = users(:norights)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    @item.submitter = user
    @item.stage     = Item::Stages::APPROVED
    policy = SubmissionPolicy.new(context, @item)
    assert !policy.edit?
  end

  test "edit?() authorizes managers of the item's collection" do
    doing_user = users(:norights)
    context    = RequestContext.new(user:        doing_user,
                                    institution: doing_user.institution)
    collection = collections(:uiuc_collection1)
    collection.managing_users << doing_user
    collection.save!
    @item.submitter          = users(:norights) # somebody else
    @item.primary_collection = collection

    policy = SubmissionPolicy.new(context, @item)
    assert policy.edit?
  end

  test "edit?() authorizes admins of the item's collection's unit" do
    doing_user = users(:norights)
    context    = RequestContext.new(user:        doing_user,
                                    institution: doing_user.institution)
    collection               = collections(:uiuc_collection1)
    unit                     = collection.primary_unit
    unit.administering_users << doing_user
    unit.save!
    @item.submitter          = users(:norights) # somebody else
    @item.primary_collection = collection

    policy = SubmissionPolicy.new(context, @item)
    assert policy.edit?
  end

  test "edit?() does not authorize anyone else" do
    user    = users(:norights)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = SubmissionPolicy.new(context, @item)
    assert !policy.edit?
  end

  test "edit?() respects role limits" do
    # sysadmin user limited to an insufficient role
    user    = users(:local_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::LOGGED_IN)
    policy  = SubmissionPolicy.new(context, @item)
    assert !policy.edit?
  end

  # new?()

  test "new?() returns false with a nil user" do
    policy = SubmissionPolicy.new(nil, @item)
    assert !policy.new?
  end

  test "new?() authorizes logged-in users" do
    user    = users(:norights)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = SubmissionPolicy.new(context, @item)
    assert policy.new?
  end

  test "new?() respects role limits" do
    # sysadmin user limited to an insufficient role
    user    = users(:local_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::LOGGED_OUT)
    policy  = SubmissionPolicy.new(context, @item)
    assert !policy.new?
  end

  # update?()

  test "update?() returns false with a nil user" do
    policy = SubmissionPolicy.new(nil, @item)
    assert !policy.update?
  end

  test "update?() does not authorize non-sysadmins" do
    user    = users(:norights)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = SubmissionPolicy.new(context, @item)
    assert !policy.update?
  end

  test "update?() authorizes sysadmins" do
    user    = users(:local_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = SubmissionPolicy.new(context, @item)
    assert policy.update?
  end

  test "update?() authorizes the submission owner if the item is submitting" do
    user    = users(:norights)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    @item.submitter = user
    @item.stage     = Item::Stages::SUBMITTING
    policy = SubmissionPolicy.new(context, @item)
    assert policy.update?
  end

  test "update?() does not authorize the submission owner if the item is not submitting" do
    user    = users(:norights)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    @item.submitter = user
    @item.stage     = Item::Stages::APPROVED
    policy = SubmissionPolicy.new(context, @item)
    assert !policy.update?
  end

  test "update?() authorizes managers of the submission's collection" do
    doing_user = users(:norights)
    context    = RequestContext.new(user:        doing_user,
                                    institution: doing_user.institution)
    collection = collections(:uiuc_collection1)
    collection.managing_users << doing_user
    collection.save!
    @item.submitter          = users(:norights) # somebody else
    @item.primary_collection = collection

    policy = SubmissionPolicy.new(context, @item)
    assert policy.update?
  end

  test "update?() authorizes admins of the submission's collection's unit" do
    doing_user = users(:norights)
    context    = RequestContext.new(user:        doing_user,
                                    institution: doing_user.institution)
    collection               = collections(:uiuc_collection1)
    unit                     = collection.primary_unit
    unit.administering_users << doing_user
    unit.save!
    @item.submitter          = users(:norights) # somebody else
    @item.primary_collection = collection

    policy = SubmissionPolicy.new(context, @item)
    assert policy.update?
  end

  test "update?() does not authorize anyone else" do
    user    = users(:norights)
    context = RequestContext.new(user:        user,
                                 institution: user.institution)
    policy  = SubmissionPolicy.new(context, @item)
    assert !policy.update?
  end

  test "update?() respects role limits" do
    # sysadmin user limited to an insufficient role
    user    = users(:local_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::LOGGED_IN)
    policy  = SubmissionPolicy.new(context, @item)
    assert !policy.update?
  end

end
