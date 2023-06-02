require 'test_helper'

class RefreshFederationMetadataJobTest < ActiveSupport::TestCase

  test "perform() creates a correct Task" do
    institution = institutions(:southwest)
    user        = users(:southwest)
    RefreshFederationMetadataJob.new.perform(institution: institution,
                                             user:        user)

    task = Task.all.order(created_at: :desc).limit(1).first
    assert_equal "RefreshFederationMetadataJob", task.name
    assert_equal institution, task.institution
    assert_equal user, task.user
    assert task.indeterminate
    assert_not_nil task.started_at
    assert task.status_text.start_with?("Updating federation")
  end

  test "perform() refreshes an institution's federation metadata" do
    institution = institutions(:southwest)
    institution.update!(saml_idp_cert: nil)

    RefreshFederationMetadataJob.new.perform(institution: institution)
    # This is tested more thoroughly in the tests of Institution
    assert_not_nil institution.saml_idp_cert
  end

end
