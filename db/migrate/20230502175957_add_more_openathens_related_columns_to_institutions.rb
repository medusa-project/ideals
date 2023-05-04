class AddMoreOpenathensRelatedColumnsToInstitutions < ActiveRecord::Migration[7.0]
  def change
    add_column :institutions, :openathens_sp_entity_id, :string
    add_column :institutions, :openathens_idp_sso_service_url, :string
    add_column :institutions, :openathens_idp_slo_service_url, :string
    add_column :institutions, :openathens_idp_cert, :text

    add_index :institutions, :openathens_sp_entity_id, unique: true
    add_index :institutions, :openathens_idp_sso_service_url, unique: true
    add_index :institutions, :openathens_idp_cert, unique: true
  end
end
