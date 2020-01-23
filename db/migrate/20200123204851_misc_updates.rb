class MiscUpdates < ActiveRecord::Migration[6.0]
  def change
    add_index :bitstreams, :key, unique: true

    remove_index :collection_unit_relationships, [:id, :primary]
    add_index :collection_unit_relationships, [:unit_id, :primary],
              name: :index_collection_units_on_unit_id_and_primary

    remove_index :item_collection_relationships, [:id, :primary]
    add_index :item_collection_relationships, [:collection_id, :primary],
              name: :index_item_collections_on_collection_id_and_primary

    drop_table :collections_items
  end
end
