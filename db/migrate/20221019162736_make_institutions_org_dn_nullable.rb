class MakeInstitutionsOrgDnNullable < ActiveRecord::Migration[7.0]
  def change
    change_column_null :institutions, :org_dn, true
  end
end
