class AddInstitutionsSamlSpCertColumns < ActiveRecord::Migration[7.0]
  def change
    add_column :institutions, :saml_sp_public_cert, :text
    add_column :institutions, :saml_sp_private_cert, :text
  end
end
