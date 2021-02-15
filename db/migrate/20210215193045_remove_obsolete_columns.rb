class RemoveObsoleteColumns < ActiveRecord::Migration[6.0]
  def change
    remove_column :collections, :primary_unit_id_deleteme if column_exists? :collections, :primary_unit_id_deleteme
    remove_column :items, :primary_collection_id_deleteme if column_exists? :items, :primary_collection_id_deleteme
    drop_table :collections_items_deleteme if table_exists? :collections_items_deleteme
    drop_table :collections_units_deleteme if table_exists? :collections_units_deleteme
  end
end
