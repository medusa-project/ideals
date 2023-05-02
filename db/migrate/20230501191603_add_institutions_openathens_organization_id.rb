class AddInstitutionsOpenathensOrganizationId < ActiveRecord::Migration[7.0]
  def change
    add_column :institutions, :openathens_organization_id, :string
    add_index :institutions, :openathens_organization_id, unique: true
    execute "UPDATE institutions SET org_dn = NULL WHERE key != 'uiuc';"
    add_index :institutions, :org_dn, unique: true
  end
end
