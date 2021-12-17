class CreateImports < ActiveRecord::Migration[6.1]
  def change
    create_table :imports do |t|
      t.bigint :collection_id, null: false
      t.bigint :user_id, null: false
      t.integer :status, null: false, default: 0
      t.float :percent_complete, null: false, default: 0
      t.text :files
      t.text :imported_items
      t.string :last_error_message
      t.timestamps
    end
    add_foreign_key :imports, :collections, on_update: :cascade, on_delete: :nullify
    add_foreign_key :imports, :users, on_update: :cascade, on_delete: :nullify
    add_index :imports, :status
  end
end
