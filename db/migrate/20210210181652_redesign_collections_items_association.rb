class RedesignCollectionsItemsAssociation < ActiveRecord::Migration[6.0]
  def up
    create_table :collection_item_memberships do |t|
      t.bigint :collection_id, null: false
      t.bigint :item_id, null: false
      t.boolean :is_primary, default: false, null: false
      t.timestamps
    end
    add_foreign_key :collection_item_memberships, :collections, on_update: :cascade, on_delete: :cascade
    add_foreign_key :collection_item_memberships, :items, on_update: :cascade, on_delete: :cascade
    add_index :collection_item_memberships, [:collection_id, :item_id], unique: true

    unless Rails.env.test?
      execute "INSERT INTO collection_item_memberships(collection_id, item_id, created_at, updated_at) "\
          "SELECT collection_id, item_id, NOW(), NOW() FROM collections_items;"
      execute "INSERT INTO collection_item_memberships(collection_id, item_id, created_at, updated_at) "\
          "SELECT primary_collection_id, id, created_at, updated_at FROM items "\
          "WHERE primary_collection_id IS NOT NULL;"

      results = execute "SELECT id, primary_collection_id FROM items "\
          "WHERE primary_collection_id IS NOT NULL;"
      results.each do |row|
        execute "UPDATE collection_item_memberships "\
            "SET is_primary = true "\
            "WHERE collection_id = #{row['primary_collection_id']} AND item_id = #{row['id']};"
      end
    end
    rename_column :collection_item_memberships, :is_primary, :primary

    rename_table :collections_items, :collections_items_deleteme

    rename_column :items, :primary_collection_id, :primary_collection_id_deleteme
  end

  def down
    drop_table :collection_item_memberships
    rename_table :collections_items_deleteme, :collections_items
    rename_column :items, :primary_collection_id_deleteme, :primary_collection_id
  end
end
