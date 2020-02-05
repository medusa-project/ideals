class RedesignManagersTable < ActiveRecord::Migration[6.0]
  def up
    remove_foreign_key :managers, :roles
    rename_column :managers, :role_id, :user_id
    add_foreign_key :managers, :users, on_update: :cascade, on_delete: :cascade
    add_index :managers, [:collection_id, :user_id], unique: true
  end
  def down
    remove_index :managers, [:collection_id, :user_id]
    execute "delete from managers;"
    remove_foreign_key :managers, :users
    rename_column :managers, :user_id, :role_id
    add_foreign_key :managers, :roles
  end
end
