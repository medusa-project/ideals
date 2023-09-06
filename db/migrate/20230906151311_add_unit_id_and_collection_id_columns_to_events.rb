class AddUnitIdAndCollectionIdColumnsToEvents < ActiveRecord::Migration[7.0]
  def change
    add_column :events, :unit_id, :bigint
    add_column :events, :collection_id, :bigint
    add_foreign_key :events, :units, on_update: :cascade, on_delete: :cascade
    add_foreign_key :events, :collections, on_update: :cascade, on_delete: :cascade
    add_index :events, :unit_id
    add_index :events, :collection_id
  end
end
