class RenameLdapGroupsToAdGroups < ActiveRecord::Migration[6.1]
  def change
    rename_column :ldap_groups_user_groups, :ldap_group_id, :ad_group_id
    rename_column :ldap_groups_users, :ldap_group_id, :ad_group_id

    rename_table :ldap_groups, :ad_groups
    rename_table :ldap_groups_user_groups, :ad_groups_user_groups
    rename_table :ldap_groups_users, :ad_groups_users
  end
end
