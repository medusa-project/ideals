class RedesignItemCollectionJoinTable < ActiveRecord::Migration[6.0]
  def up
    drop_table :item_collection_relationships
    create_join_table :collections, :items
    add_foreign_key :collections_items, :collections,
                    on_update: :cascade, on_delete: :restrict
    add_foreign_key :collections_items, :items,
                    on_update: :cascade, on_delete: :cascade
    add_index :collections_items, [:collection_id, :item_id], unique: true
    add_column :items, :primary_collection_id, :bigint
    add_foreign_key :items, :collections, column: :primary_collection_id,
                    on_update: :cascade, on_delete: :restrict
  end
  def down
    drop_table :collections_items
    create_table :item_collection_relationships do |t|
      t.timestamps
    end
    remove_column :collections, :primary_unit_id
  end
end
