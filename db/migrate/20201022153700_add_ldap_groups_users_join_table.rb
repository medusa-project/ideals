class AddLdapGroupsUsersJoinTable < ActiveRecord::Migration[6.0]
  def change
    create_join_table :ldap_groups, :users
  end
end
