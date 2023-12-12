require 'test_helper'

class RefreshSamlConfigMetadataJobTest < ActiveSupport::TestCase

  test "perform() updates the Task given to it" do
    institution = institutions(:southwest)
    user        = users(:southwest)
    task        = tasks(:pending)
    RefreshSamlConfigMetadataJob.perform_now(institution: institution,
                                             user:        user,
                                             task:        task)

    task.reload
    assert_equal "RefreshSamlConfigMetadataJob", task.name
    assert_equal institution, task.institution
    assert_equal user, task.user
    assert task.indeterminate
    assert_equal RefreshSamlConfigMetadataJob::QUEUE.to_s, task.queue
    assert_not_empty task.job_id
    assert_not_nil task.started_at
    assert task.status_text.start_with?("Updating SAML configuration")
  end

  test "perform() refreshes an institution's federation metadata" do
    institution = institutions(:southwest)
    institution.update!(saml_idp_signing_cert: nil)

    RefreshSamlConfigMetadataJob.perform_now(institution: institution)
    # This is tested more thoroughly in the tests of Institution
    assert_not_nil institution.saml_idp_signing_cert
  end

  test "perform() updates an institution's metadata from a local XML file" do
    institution = institutions(:southwest)
    institution.update!(sso_federation:        Institution::SSOFederation::NONE,
                        saml_idp_signing_cert: nil)

    RefreshSamlConfigMetadataJob.perform_now(institution:       institution,
                                             configuration_xml: file_fixture("southwest_saml.xml"))
    # This is tested more thoroughly in the tests of Institution
    assert_not_nil institution.saml_idp_signing_cert
  end

  test "perform() updates an institution's metadata from a remote XML file" do
    skip # TODO: write this
  end

  test "perform() updates the value of saml_metadata_url when updating an
  institution's metadata from a remote XML file" do
    institution = institutions(:southwest)
    institution.update!(sso_federation:        Institution::SSOFederation::NONE,
                        saml_idp_signing_cert: nil)
    url = "https://example.org/metadata.xml"

    assert_raises ArgumentError do
      # This is going to raise an ArgumentError, but the property should still
      # get set.
      RefreshSamlConfigMetadataJob.perform_now(institution:       institution,
                                               configuration_url: url)
    end
    assert_equal url, institution.saml_metadata_url
  end

end
