class CreateLdapGroups < ActiveRecord::Migration[6.0]
  def change
    create_table :ldap_groups do |t|
      t.string :name
      t.timestamps
    end
    add_index :ldap_groups, :name, unique: true

    create_join_table :ldap_groups, :user_groups
    add_foreign_key :ldap_groups_user_groups, :ldap_groups
    add_foreign_key :ldap_groups_user_groups, :user_groups
  end
end
