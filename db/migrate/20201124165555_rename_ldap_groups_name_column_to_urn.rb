class RenameLdapGroupsNameColumnToUrn < ActiveRecord::Migration[6.0]
  def change
    rename_column :ldap_groups, :name, :urn
  end
end
