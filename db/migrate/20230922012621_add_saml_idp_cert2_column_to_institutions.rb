class AddSamlIdpCert2ColumnToInstitutions < ActiveRecord::Migration[7.0]
  def change
    add_column :institutions, :saml_idp_cert2, :text
  end
end
