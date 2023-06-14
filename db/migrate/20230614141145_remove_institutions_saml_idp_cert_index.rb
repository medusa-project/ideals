class RemoveInstitutionsSamlIdpCertIndex < ActiveRecord::Migration[7.0]
  def change
    remove_index :institutions, :saml_idp_cert
  end
end
