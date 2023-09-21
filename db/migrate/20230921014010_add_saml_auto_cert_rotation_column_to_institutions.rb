class AddSamlAutoCertRotationColumnToInstitutions < ActiveRecord::Migration[7.0]
  def change
    add_column :institutions, :saml_auto_cert_rotation, :boolean, default: true
    add_index :institutions, :saml_auto_cert_rotation
  end
end
