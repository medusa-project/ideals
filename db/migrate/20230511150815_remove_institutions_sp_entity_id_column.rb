class RemoveInstitutionsSpEntityIdColumn < ActiveRecord::Migration[7.0]
  def change
    remove_column :institutions, :saml_sp_entity_id
    add_column :institutions, :saml_idp_entity_id, :string
    add_index :institutions, :saml_idp_entity_id, unique: true
  end
end
