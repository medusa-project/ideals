class AddForeignKeys < ActiveRecord::Migration[6.0]
  def change
    remove_foreign_key :collection_unit_relationships, :collections
    remove_foreign_key :collection_unit_relationships, :units
    remove_foreign_key :item_collection_relationships, :collections
    remove_foreign_key :item_collection_relationships, :items

    add_foreign_key :collection_unit_relationships, :collections, on_update: :cascade, on_delete: :cascade
    add_foreign_key :collection_unit_relationships, :units, on_update: :cascade, on_delete: :cascade
    add_foreign_key :item_collection_relationships, :collections, on_update: :cascade, on_delete: :cascade
    add_foreign_key :item_collection_relationships, :items, on_update: :cascade, on_delete: :cascade
  end
end
