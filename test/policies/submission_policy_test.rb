require 'test_helper'

class SubmissionPolicyTest < ActiveSupport::TestCase

  setup do
    @user       = users(:sally)
    @submission = submissions(:one)
  end

  # create?()

  test "create?() returns false with a nil user" do
    policy = SubmissionPolicy.new(nil, @submission)
    assert !policy.create?
  end

  test "create?() authorizes logged-in users" do
    policy = SubmissionPolicy.new(users(:norights), @submission)
    assert policy.create?
  end

  # deposit?()

  test "deposit?() returns false with a nil user" do
    policy = SubmissionPolicy.new(nil, @submission)
    assert !policy.deposit?
  end

  test "deposit?() authorizes logged-in users" do
    policy = SubmissionPolicy.new(users(:norights), @submission)
    assert policy.deposit?
  end

  # destroy?()

  test "destroy?() returns false with a nil user" do
    policy = SubmissionPolicy.new(nil, @submission)
    assert !policy.destroy?
  end

  test "destroy?() does not authorize non-sysadmins" do
    policy = SubmissionPolicy.new(users(:norights), @submission)
    assert !policy.destroy?
  end

  test "destroy?() authorizes sysadmins" do
    policy = SubmissionPolicy.new(users(:admin), @submission)
    assert policy.destroy?
  end

  test "destroy?() authorizes the submission owner" do
    user = users(:norights)
    @submission.user = user
    policy = SubmissionPolicy.new(user, @submission)
    assert policy.destroy?
  end

  test "destroy?() authorizes managers of the submission's collection" do
    doing_user = users(:norights)
    collection = collections(:collection1)
    collection.managing_users << doing_user
    collection.save!
    @submission.user       = users(:sally) # somebody else
    @submission.collection = collection

    policy = SubmissionPolicy.new(doing_user, @submission)
    assert policy.destroy?
  end

  test "destroy?() authorizes admins of the submission's collection's unit" do
    doing_user               = users(:norights)
    collection               = collections(:collection1)
    unit                     = collection.primary_unit
    unit.administering_users << doing_user
    unit.save!
    @submission.user       = users(:sally) # somebody else
    @submission.collection = collection

    policy = SubmissionPolicy.new(doing_user, @submission)
    assert policy.destroy?
  end

  test "destroy?() does not authorize anyone else" do
    policy = SubmissionPolicy.new(users(:norights), @submission)
    assert !policy.destroy?
  end

  # edit?()

  test "edit?() returns false with a nil user" do
    policy = SubmissionPolicy.new(nil, @submission)
    assert !policy.edit?
  end

  test "edit?() does not authorize non-sysadmins" do
    policy = SubmissionPolicy.new(users(:norights), @submission)
    assert !policy.edit?
  end

  test "edit?() authorizes sysadmins" do
    policy = SubmissionPolicy.new(users(:admin), @submission)
    assert policy.edit?
  end

  test "edit?() authorizes the submission owner" do
    user = users(:norights)
    @submission.user = user
    policy = SubmissionPolicy.new(user, @submission)
    assert policy.edit?
  end

  test "edit?() authorizes managers of the submission's collection" do
    doing_user = users(:norights)
    collection = collections(:collection1)
    collection.managing_users << doing_user
    collection.save!
    @submission.user       = users(:sally) # somebody else
    @submission.collection = collection

    policy = SubmissionPolicy.new(doing_user, @submission)
    assert policy.edit?
  end

  test "edit?() authorizes admins of the submission's collection's unit" do
    doing_user               = users(:norights)
    collection               = collections(:collection1)
    unit                     = collection.primary_unit
    unit.administering_users << doing_user
    unit.save!
    @submission.user       = users(:sally) # somebody else
    @submission.collection = collection

    policy = SubmissionPolicy.new(doing_user, @submission)
    assert policy.edit?
  end

  test "edit?() does not authorize anyone else" do
    policy = SubmissionPolicy.new(users(:norights), @submission)
    assert !policy.edit?
  end

  # update?()

  test "update?() returns false with a nil user" do
    policy = SubmissionPolicy.new(nil, @submission)
    assert !policy.update?
  end

  test "update?() does not authorize non-sysadmins" do
    policy = SubmissionPolicy.new(users(:norights), @submission)
    assert !policy.update?
  end

  test "update?() authorizes sysadmins" do
    policy = SubmissionPolicy.new(users(:admin), @submission)
    assert policy.update?
  end

  test "update?() authorizes the submission owner" do
    user = users(:norights)
    @submission.user = user
    policy = SubmissionPolicy.new(user, @submission)
    assert policy.update?
  end

  test "update?() authorizes managers of the submission's collection" do
    doing_user = users(:norights)
    collection = collections(:collection1)
    collection.managing_users << doing_user
    collection.save!
    @submission.user       = users(:sally) # somebody else
    @submission.collection = collection

    policy = SubmissionPolicy.new(doing_user, @submission)
    assert policy.update?
  end

  test "update?() authorizes admins of the submission's collection's unit" do
    doing_user               = users(:norights)
    collection               = collections(:collection1)
    unit                     = collection.primary_unit
    unit.administering_users << doing_user
    unit.save!
    @submission.user       = users(:sally) # somebody else
    @submission.collection = collection

    policy = SubmissionPolicy.new(doing_user, @submission)
    assert policy.update?
  end

  test "update?() does not authorize anyone else" do
    policy = SubmissionPolicy.new(users(:norights), @submission)
    assert !policy.update?
  end

end
