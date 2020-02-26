class CreateUserGroups < ActiveRecord::Migration[6.0]
  def change
    create_table :user_groups do |t|
      t.string :name, null: false

      t.timestamps
    end
    add_index :user_groups, :name, unique: true

    create_join_table :users, :user_groups
    add_foreign_key :user_groups_users, :users, on_update: :cascade, on_delete: :cascade
    add_foreign_key :user_groups_users, :user_groups, on_update: :cascade, on_delete: :cascade
  end
end
