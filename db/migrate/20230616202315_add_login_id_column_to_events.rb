class AddLoginIdColumnToEvents < ActiveRecord::Migration[7.0]
  def change
    add_column :events, :login_id, :bigint
    add_index :events, :login_id
    add_foreign_key :events, :logins, on_update: :cascade, on_delete: :nullify
  end
end
