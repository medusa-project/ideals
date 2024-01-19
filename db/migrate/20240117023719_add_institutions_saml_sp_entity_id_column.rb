class AddInstitutionsSamlSpEntityIdColumn < ActiveRecord::Migration[7.1]
  def change
    add_column :institutions, :saml_sp_entity_id, :string
  end
end
