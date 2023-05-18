require 'test_helper'

class VocabularyTermPolicyTest < ActiveSupport::TestCase

  setup do
    @term = vocabulary_terms(:southwest_one_one)
  end

  # create?()

  test "create?() returns false with a nil user" do
    context = RequestContext.new(user:        nil,
                                 institution: @term.vocabulary.institution)
    policy = VocabularyTermPolicy.new(context, @term)
    assert !policy.create?
  end

  test "create?() does not authorize non-privileged users" do
    user    = users(:southwest)
    context = RequestContext.new(user:        user,
                                 institution: @term.vocabulary.institution)
    policy  = VocabularyTermPolicy.new(context, @term)
    assert !policy.create?
  end

  test "create?() authorizes administrators of the same institution" do
    user = users(:southwest_admin)
    context = RequestContext.new(user:        user,
                                 institution: @term.vocabulary.institution)
    policy  = VocabularyTermPolicy.new(context, @term)
    assert policy.create?
  end

  test "create?() does not authorize administrators of a different
  institution than in the request context" do
    user    = users(:southwest_admin)
    context = RequestContext.new(user:        user,
                                 institution: institutions(:northeast))
    policy  = VocabularyTermPolicy.new(context, @term)
    assert !policy.create?
  end

  test "create?() respects role limits" do
    # sysadmin user limited to an insufficient role
    user    = users(:southwest_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::LOGGED_IN)
    policy  = VocabularyTermPolicy.new(context, @term)
    assert !policy.create?
  end

  # destroy?()

  test "destroy?() returns false with a nil user" do
    context = RequestContext.new(user:        nil,
                                 institution: @term.vocabulary.institution)
    policy = VocabularyTermPolicy.new(context, @term)
    assert !policy.destroy?
  end

  test "destroy?() does not authorize an incorrect scope" do
    context = RequestContext.new(user:        users(:southwest_admin),
                                 institution: institutions(:northeast))
    policy  = VocabularyTermPolicy.new(context, @term)
    assert !policy.destroy?
  end

  test "destroy?() does not authorize non-privileged users" do
    user    = users(:southwest)
    context = RequestContext.new(user:        user,
                                 institution: @term.vocabulary.institution)
    policy  = VocabularyTermPolicy.new(context, @term)
    assert !policy.destroy?
  end

  test "destroy?() authorizes administrators of the same institution" do
    user = users(:southwest_admin)
    context = RequestContext.new(user:        user,
                                 institution: @term.vocabulary.institution)
    policy  = VocabularyTermPolicy.new(context, @term)
    assert policy.destroy?
  end

  test "destroy?() does not authorize administrators of a different
  institution than in the request context" do
    user    = users(:southwest_admin)
    context = RequestContext.new(user:        user,
                                 institution: institutions(:northeast))
    policy  = VocabularyTermPolicy.new(context, @term)
    assert !policy.destroy?
  end

  test "destroy?() does not authorize administrators of a different
  institution than the vocabulary" do
    user    = users(:northeast_admin)
    context = RequestContext.new(user:        user,
                                 institution: institutions(:northeast))
    policy  = VocabularyTermPolicy.new(context, @term)
    assert !policy.destroy?
  end

  test "destroy?() respects role limits" do
    # sysadmin user limited to an insufficient role
    user    = users(:southwest_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::LOGGED_IN)
    policy  = VocabularyTermPolicy.new(context, @term)
    assert !policy.destroy?
  end

  # edit?()

  test "edit?() returns false with a nil user" do
    context = RequestContext.new(user:        nil,
                                 institution: @term.vocabulary.institution)
    policy = VocabularyTermPolicy.new(context, @term)
    assert !policy.edit?
  end

  test "edit?() does not authorize an incorrect scope" do
    context = RequestContext.new(user:        users(:southwest_admin),
                                 institution: institutions(:northeast))
    policy  = VocabularyTermPolicy.new(context, @term)
    assert !policy.edit?
  end

  test "edit?() does not authorize non-privileged users" do
    user    = users(:southwest)
    context = RequestContext.new(user:        user,
                                 institution: @term.vocabulary.institution)
    policy  = VocabularyTermPolicy.new(context, @term)
    assert !policy.edit?
  end

  test "edit?() authorizes administrators of the same institution" do
    user = users(:southwest_admin)
    context = RequestContext.new(user:        user,
                                 institution: @term.vocabulary.institution)
    policy  = VocabularyTermPolicy.new(context, @term)
    assert policy.edit?
  end

  test "edit?() does not authorize administrators of a different institution
  than in the request context" do
    user    = users(:southwest_admin)
    context = RequestContext.new(user:        user,
                                 institution: institutions(:northeast))
    policy  = VocabularyTermPolicy.new(context, @term)
    assert !policy.edit?
  end

  test "edit?() does not authorize administrators of a different institution
  than the vocabulary" do
    user    = users(:northeast_admin)
    context = RequestContext.new(user:        user,
                                 institution: institutions(:northeast))
    policy  = VocabularyTermPolicy.new(context, @term)
    assert !policy.edit?
  end

  test "edit?() respects role limits" do
    # sysadmin user limited to an insufficient role
    user    = users(:southwest_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::LOGGED_IN)
    policy  = VocabularyTermPolicy.new(context, @term)
    assert !policy.edit?
  end

  # import?()

  test "import?() returns false with a nil user" do
    context = RequestContext.new(user:        nil,
                                 institution: @term.vocabulary.institution)
    policy = VocabularyTermPolicy.new(context, @term)
    assert !policy.import?
  end

  test "import?() does not authorize non-privileged users" do
    user    = users(:southwest)
    context = RequestContext.new(user:        user,
                                 institution: @term.vocabulary.institution)
    policy  = VocabularyTermPolicy.new(context, @term)
    assert !policy.import?
  end

  test "import?() authorizes administrators of the same institution" do
    user = users(:southwest_admin)
    context = RequestContext.new(user:        user,
                                 institution: @term.vocabulary.institution)
    policy  = VocabularyTermPolicy.new(context, @term)
    assert policy.import?
  end

  test "import?() does not authorize administrators of a different
  institution than in the request context" do
    user    = users(:southwest_admin)
    context = RequestContext.new(user:        user,
                                 institution: institutions(:northeast))
    policy  = VocabularyTermPolicy.new(context, @term)
    assert !policy.import?
  end

  test "import?() respects role limits" do
    # sysadmin user limited to an insufficient role
    user    = users(:southwest_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::LOGGED_IN)
    policy  = VocabularyTermPolicy.new(context, @term)
    assert !policy.import?
  end

  # new()

  test "new?() returns false with a nil user" do
    context = RequestContext.new(user:        nil,
                                 institution: @term.vocabulary.institution)
    policy = VocabularyTermPolicy.new(context, @term)
    assert !policy.new?
  end

  test "new?() does not authorize non-privileged users" do
    user    = users(:southwest)
    context = RequestContext.new(user:        user,
                                 institution: @term.vocabulary.institution)
    policy = VocabularyTermPolicy.new(context, @term)
    assert !policy.new?
  end

  test "new?() authorizes institution administrators" do
    user = users(:southwest_admin)
    context = RequestContext.new(user:        user,
                                 institution: @term.vocabulary.institution)
    policy  = VocabularyTermPolicy.new(context, @term)
    assert policy.new?
  end

  test "new?() does not authorize administrators of a different
  institution" do
    user    = users(:southwest_admin)
    context = RequestContext.new(user:        user,
                                 institution: institutions(:northeast))
    policy  = VocabularyTermPolicy.new(context, @term)
    assert !policy.new?
  end

  test "new?() respects role limits" do
    # sysadmin user limited to an insufficient role
    user    = users(:southwest_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::LOGGED_IN)
    policy  = VocabularyTermPolicy.new(context, @term)
    assert !policy.new?
  end

  # update?()

  test "update?() returns false with a nil user" do
    context = RequestContext.new(user:        nil,
                                 institution: @term.vocabulary.institution)
    policy = VocabularyTermPolicy.new(context, @term)
    assert !policy.update?
  end

  test "update?() does not authorize an incorrect scope" do
    context = RequestContext.new(user:        users(:southwest_admin),
                                 institution: institutions(:northeast))
    policy  = VocabularyTermPolicy.new(context, @term)
    assert !policy.update?
  end

  test "update?() does not authorize non-privileged users" do
    user    = users(:southwest)
    context = RequestContext.new(user:        user,
                                 institution: @term.vocabulary.institution)
    policy = VocabularyTermPolicy.new(context, @term)
    assert !policy.update?
  end

  test "update?() authorizes administrators of the same institution" do
    user = users(:southwest_admin)
    context = RequestContext.new(user:        user,
                                 institution: @term.vocabulary.institution)
    policy  = VocabularyTermPolicy.new(context, @term)
    assert policy.update?
  end

  test "update?() does not authorize administrators of a different institution
  than in the request context" do
    user    = users(:southwest_admin)
    context = RequestContext.new(user:        user,
                                 institution: institutions(:northeast))
    policy  = VocabularyTermPolicy.new(context, @term)
    assert !policy.update?
  end

  test "update?() does not authorize administrators of a different institution
  than the vocabulary" do
    user    = users(:northeast_admin)
    context = RequestContext.new(user:        user,
                                 institution: institutions(:northeast))
    policy  = VocabularyTermPolicy.new(context, @term)
    assert !policy.update?
  end

  test "update?() respects role limits" do
    # sysadmin user limited to an insufficient role
    user    = users(:southwest_sysadmin)
    context = RequestContext.new(user:        user,
                                 institution: user.institution,
                                 role_limit:  Role::LOGGED_IN)
    policy  = VocabularyTermPolicy.new(context, @term)
    assert !policy.update?
  end

end
