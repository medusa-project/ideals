require 'test_helper'

class RefreshOpenathensMetadataJobTest < ActiveSupport::TestCase

  test "perform() refreshes an institution's OpenAthens metadata" do
    institution = institutions(:southwest)
    institution.update!(saml_idp_cert: nil)

    RefreshOpenathensMetadataJob.new.perform(institution)
    # This is tested more thoroughly in the tests of Institution
    assert_not_nil institution.saml_idp_cert
  end

end
