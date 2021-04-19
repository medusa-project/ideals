class CreateEmbargoes < ActiveRecord::Migration[6.0]
  def change
    create_table :embargoes do |t|
      t.datetime :expires_at, null: false
      t.boolean :full_access, null: false, default: true
      t.boolean :download, null: false, default: true
      t.bigint :item_id

      t.timestamps
    end
    add_index :embargoes, :expires_at
    add_foreign_key :embargoes, :items, on_update: :cascade, on_delete: :cascade
  end
end
