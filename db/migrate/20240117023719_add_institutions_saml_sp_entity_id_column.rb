class AddInstitutionsSamlSpEntityIdColumn < ActiveRecord::Migration[7.1]
  def change
    unless column_exists?(:institutions, :saml_sp_entity_id)
      add_column :institutions, :saml_sp_entity_id, :string
    end
  end
end
