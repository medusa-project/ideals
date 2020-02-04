class RedesignAdministratorsTable < ActiveRecord::Migration[6.0]
  def up
    remove_foreign_key :administrators, :roles
    rename_column :administrators, :role_id, :user_id
    add_foreign_key :administrators, :users,
                    on_update: :cascade, on_delete: :cascade
    #add_index :administrators, [:unit_id, :user_id], unique: true

    add_column :administrators, :primary, :boolean, default: false, null: false
    add_index :administrators, [:user_id, :unit_id, :primary]

    remove_column :units, :primary_administrator_id
  end
  def down
    add_column :units, :primary_administrator_id, :integer

    #remove_index :administrators, [:unit_id, :user_id]
    remove_index :administrators, name: "index_administrators_on_unit_id_and_user_id_uniq"

    execute "delete from administrators;"
    remove_index :administrators, [:user_id, :unit_id, :primary]
    remove_column :administrators, :primary
    remove_foreign_key :administrators, :users
    rename_column :administrators, :user_id, :role_id
    add_foreign_key :administrators, :roles
  end
end
