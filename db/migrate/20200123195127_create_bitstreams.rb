class CreateBitstreams < ActiveRecord::Migration[6.0]
  def change
    create_table :bitstreams do |t|
      t.string :key, null: false
      t.bigint :length
      t.string :media_type
      t.integer :item_id

      t.timestamps
    end
    add_foreign_key :bitstreams, :items, on_update: :cascade, on_delete: :cascade
  end
end
