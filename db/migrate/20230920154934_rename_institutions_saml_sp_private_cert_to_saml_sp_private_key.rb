class RenameInstitutionsSamlSpPrivateCertToSamlSpPrivateKey < ActiveRecord::Migration[7.0]
  def change
    rename_column :institutions, :saml_sp_private_cert, :saml_sp_private_key
  end
end
