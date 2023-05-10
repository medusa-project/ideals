class RemoveInstitutionsOpenathensOrganizationIdColumn < ActiveRecord::Migration[7.0]
  def change
    remove_column :institutions, :openathens_organization_id
  end
end
