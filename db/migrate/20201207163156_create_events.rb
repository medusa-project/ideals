class CreateEvents < ActiveRecord::Migration[6.0]
  def change
    create_table :events do |t|
      t.integer :event_type, null: false
      t.bigint :user_id
      t.text :description
      t.text :before_changes
      t.text :after_changes
      t.bigint :item_id, null: false
      t.timestamps
    end
    add_foreign_key :events, :items, on_update: :cascade, on_delete: :cascade
    add_foreign_key :events, :users, on_update: :cascade, on_delete: :cascade
  end
end
