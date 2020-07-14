class RedesignHandles < ActiveRecord::Migration[6.0]
  def up
    drop_table :handles if table_exists? :handles

    create_table :handles do |t|
      t.string :prefix, null: false
      t.serial :suffix, null: false
      t.bigint :unit_id
      t.bigint :collection_id
      t.bigint :item_id
      t.timestamps
    end
    add_index :handles, :suffix, unique: true
    add_foreign_key :handles, :units, on_update: :cascade, on_delete: :cascade
    add_foreign_key :handles, :collections, on_update: :cascade, on_delete: :cascade
    add_foreign_key :handles, :items, on_update: :cascade, on_delete: :cascade
  end

  def down
    drop_table :handles
  end
end
