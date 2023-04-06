class RenameCollectionManagersToAdministrators < ActiveRecord::Migration[7.0]
  def change
    remove_index :manager_groups, [:collection_id, :user_group_id]
    rename_table :collection_managers, :collection_administrators
    rename_table :manager_groups, :collection_administrator_groups
    add_index :collection_administrator_groups,
              [:collection_id, :user_group_id],
              name: "index_collection_admin_groups_on_col_id_and_user_group_id",
              unique: true
  end
end
