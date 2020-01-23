class CreateItemCollectionRelationships < ActiveRecord::Migration[6.0]
  def change
    remove_column :items, :primary_collection_id
    create_table :item_collection_relationships do |t|
      t.integer :collection_id
      t.integer :item_id
      t.boolean :primary, default: false, null: false
      t.timestamps
    end
    add_index :item_collection_relationships, [:id, :primary]
    add_foreign_key :item_collection_relationships, :items
    add_foreign_key :item_collection_relationships, :collections
  end
end
