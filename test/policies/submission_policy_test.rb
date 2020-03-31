require 'test_helper'

class SubmissionPolicyTest < ActiveSupport::TestCase

  setup do
    @item = items(:item1)
  end

  # agreement?()

  test "agreement?() returns false with a nil user" do
    policy = SubmissionPolicy.new(nil, @item)
    assert !policy.agreement?
  end

  test "agreement?() authorizes logged-in users" do
    context = UserContext.new(users(:norights), Role::NO_LIMIT)
    policy  = SubmissionPolicy.new(context, @item)
    assert policy.agreement?
  end

  test "agreement?() respects role limits" do
    # sysadmin user limited to an insufficient role
    context = UserContext.new(users(:admin), Role::LOGGED_OUT)
    policy  = SubmissionPolicy.new(context, @item)
    assert !policy.agreement?
  end

  # destroy?()

  test "destroy?() returns false with a nil user" do
    policy = SubmissionPolicy.new(nil, @item)
    assert !policy.destroy?
  end

  test "destroy?() does not authorize non-sysadmins" do
    context = UserContext.new(users(:norights), Role::NO_LIMIT)
    policy = SubmissionPolicy.new(context, @item)
    assert !policy.destroy?
  end

  test "destroy?() authorizes sysadmins" do
    context = UserContext.new(users(:admin), Role::NO_LIMIT)
    policy = SubmissionPolicy.new(context, @item)
    assert policy.destroy?
  end

  test "destroy?() authorizes the submission owner if the item is submitting" do
    user    = users(:norights)
    context = UserContext.new(user, Role::NO_LIMIT)
    @item.submitter  = user
    @item.submitting = true
    policy = SubmissionPolicy.new(context, @item)
    assert policy.destroy?
  end

  test "destroy?() does not authorize the submission owner if the item is not submitting" do
    user    = users(:norights)
    context = UserContext.new(user, Role::NO_LIMIT)
    @item.submitter = user
    @item.submitting = false
    policy = SubmissionPolicy.new(context, @item)
    assert !policy.destroy?
  end

  test "destroy?() authorizes managers of the submission's collection" do
    doing_user = users(:norights)
    context    = UserContext.new(doing_user, Role::NO_LIMIT)
    collection = collections(:collection1)
    collection.managing_users << doing_user
    collection.save!
    @item.submitter          = users(:sally) # somebody else
    @item.primary_collection = collection

    policy = SubmissionPolicy.new(context, @item)
    assert policy.destroy?
  end

  test "destroy?() authorizes admins of the submission's collection's unit" do
    doing_user               = users(:norights)
    context                  = UserContext.new(doing_user, Role::NO_LIMIT)
    collection               = collections(:collection1)
    unit                     = collection.primary_unit
    unit.administering_users << doing_user
    unit.save!
    @item.submitter          = users(:sally) # somebody else
    @item.primary_collection = collection

    policy = SubmissionPolicy.new(context, @item)
    assert policy.destroy?
  end

  test "destroy?() does not authorize anyone else" do
    context = UserContext.new(users(:norights), Role::NO_LIMIT)
    policy  = SubmissionPolicy.new(context, @item)
    assert !policy.destroy?
  end

  test "destroy?() respects role limits" do
    # sysadmin user limited to an insufficient role
    context = UserContext.new(users(:admin), Role::LOGGED_IN)
    policy  = SubmissionPolicy.new(context, @item)
    assert !policy.destroy?
  end

  # edit?()

  test "edit?() returns false with a nil user" do
    policy = SubmissionPolicy.new(nil, @item)
    assert !policy.edit?
  end

  test "edit?() does not authorize non-sysadmins" do
    context = UserContext.new(users(:norights), Role::NO_LIMIT)
    policy  = SubmissionPolicy.new(context, @item)
    assert !policy.edit?
  end

  test "edit?() authorizes sysadmins" do
    context = UserContext.new(users(:admin), Role::NO_LIMIT)
    policy = SubmissionPolicy.new(context, @item)
    assert policy.edit?
  end

  test "edit?() authorizes the submission owner if the item is submitting" do
    user    = users(:norights)
    context = UserContext.new(user, Role::NO_LIMIT)
    @item.submitter = user
    @item.submitting = true
    policy = SubmissionPolicy.new(context, @item)
    assert policy.edit?
  end

  test "edit?() does not authorize the submission owner if the item is not submitting" do
    user    = users(:norights)
    context = UserContext.new(user, Role::NO_LIMIT)
    @item.submitter = user
    @item.submitting = false
    policy = SubmissionPolicy.new(context, @item)
    assert !policy.edit?
  end

  test "edit?() authorizes managers of the item's collection" do
    doing_user = users(:norights)
    context    = UserContext.new(doing_user, Role::NO_LIMIT)
    collection = collections(:collection1)
    collection.managing_users << doing_user
    collection.save!
    @item.submitter          = users(:sally) # somebody else
    @item.primary_collection = collection

    policy = SubmissionPolicy.new(context, @item)
    assert policy.edit?
  end

  test "edit?() authorizes admins of the item's collection's unit" do
    doing_user               = users(:norights)
    context                  = UserContext.new(doing_user, Role::NO_LIMIT)
    collection               = collections(:collection1)
    unit                     = collection.primary_unit
    unit.administering_users << doing_user
    unit.save!
    @item.submitter          = users(:sally) # somebody else
    @item.primary_collection = collection

    policy = SubmissionPolicy.new(context, @item)
    assert policy.edit?
  end

  test "edit?() does not authorize anyone else" do
    context = UserContext.new(users(:norights), Role::NO_LIMIT)
    policy  = SubmissionPolicy.new(context, @item)
    assert !policy.edit?
  end

  test "edit?() respects role limits" do
    # sysadmin user limited to an insufficient role
    context = UserContext.new(users(:admin), Role::LOGGED_IN)
    policy  = SubmissionPolicy.new(context, @item)
    assert !policy.edit?
  end

  # update?()

  test "update?() returns false with a nil user" do
    policy = SubmissionPolicy.new(nil, @item)
    assert !policy.update?
  end

  test "update?() does not authorize non-sysadmins" do
    context = UserContext.new(users(:norights), Role::NO_LIMIT)
    policy = SubmissionPolicy.new(context, @item)
    assert !policy.update?
  end

  test "update?() authorizes sysadmins" do
    context = UserContext.new(users(:admin), Role::NO_LIMIT)
    policy = SubmissionPolicy.new(context, @item)
    assert policy.update?
  end

  test "update?() authorizes the submission owner if the item is submitting" do
    user    = users(:norights)
    context = UserContext.new(user, Role::NO_LIMIT)
    @item.submitter = user
    @item.submitting = true
    policy = SubmissionPolicy.new(context, @item)
    assert policy.update?
  end

  test "update?() does not authorize the submission owner if the item is not submitting" do
    user    = users(:norights)
    context = UserContext.new(user, Role::NO_LIMIT)
    @item.submitter = user
    @item.submitting = false
    policy = SubmissionPolicy.new(context, @item)
    assert !policy.update?
  end

  test "update?() authorizes managers of the submission's collection" do
    doing_user = users(:norights)
    context    = UserContext.new(doing_user, Role::NO_LIMIT)
    collection = collections(:collection1)
    collection.managing_users << doing_user
    collection.save!
    @item.submitter          = users(:sally) # somebody else
    @item.primary_collection = collection

    policy = SubmissionPolicy.new(context, @item)
    assert policy.update?
  end

  test "update?() authorizes admins of the submission's collection's unit" do
    doing_user               = users(:norights)
    context                  = UserContext.new(doing_user, Role::NO_LIMIT)
    collection               = collections(:collection1)
    unit                     = collection.primary_unit
    unit.administering_users << doing_user
    unit.save!
    @item.submitter          = users(:sally) # somebody else
    @item.primary_collection = collection

    policy = SubmissionPolicy.new(context, @item)
    assert policy.update?
  end

  test "update?() does not authorize anyone else" do
    context = UserContext.new(users(:norights), Role::NO_LIMIT)
    policy  = SubmissionPolicy.new(context, @item)
    assert !policy.update?
  end

  test "update?() respects role limits" do
    # sysadmin user limited to an insufficient role
    context = UserContext.new(users(:admin), Role::LOGGED_IN)
    policy  = SubmissionPolicy.new(context, @item)
    assert !policy.update?
  end

end
