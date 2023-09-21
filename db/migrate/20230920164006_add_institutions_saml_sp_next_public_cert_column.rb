class AddInstitutionsSamlSpNextPublicCertColumn < ActiveRecord::Migration[7.0]
  def change
    add_column :institutions, :saml_sp_next_public_cert, :text
  end
end
