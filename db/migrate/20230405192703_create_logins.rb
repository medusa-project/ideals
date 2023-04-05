class CreateLogins < ActiveRecord::Migration[7.0]
  def change
    create_table :logins do |t|
      t.bigint :user_id
      t.string :ip_address
      t.string :hostname
      t.text :auth_hash

      t.timestamps
    end
    add_foreign_key :logins, :users, on_update: :cascade, on_delete: :cascade
    add_index :logins, :user_id
    add_index :logins, :created_at
    remove_column :users, :last_logged_in_at
    remove_column :users, :auth_hash
  end
end
