class RemoveInstitutionsSamlIdpSsoServiceUrlUniqueIndex < ActiveRecord::Migration[7.0]
  def change
    remove_index :institutions, :saml_idp_sso_service_url
  end
end
