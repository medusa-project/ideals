class RenameInstitutionsOrgDnToShibbolethOrgDn < ActiveRecord::Migration[7.0]
  def change
    rename_column :institutions, :org_dn, :shibboleth_org_dn
  end
end
