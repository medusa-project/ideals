class AddIdpSamlCertUseColumnsToInstitutions < ActiveRecord::Migration[7.0]
  def change
    rename_column :institutions, :saml_idp_cert, :saml_idp_signing_cert
    rename_column :institutions, :saml_idp_cert2, :saml_idp_signing_cert2
    add_column :institutions, :saml_idp_encryption_cert, :text
    add_column :institutions, :saml_idp_encryption_cert2, :text
    execute "UPDATE institutions SET saml_idp_encryption_cert = saml_idp_signing_cert;"
    execute "UPDATE institutions SET saml_idp_encryption_cert2 = saml_idp_signing_cert2;"
  end
end
