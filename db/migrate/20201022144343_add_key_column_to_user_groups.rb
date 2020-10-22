class AddKeyColumnToUserGroups < ActiveRecord::Migration[6.0]
  def change
    add_column :user_groups, :key, :string
    execute "update user_groups set key = random()::text;"
    change_column_null :user_groups, :key, false
    add_index :user_groups, :key, unique: true
  end
end
