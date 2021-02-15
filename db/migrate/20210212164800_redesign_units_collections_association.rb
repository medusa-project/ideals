class RedesignUnitsCollectionsAssociation < ActiveRecord::Migration[6.0]
  def up
    create_table :unit_collection_memberships do |t|
      t.bigint :collection_id, null: false
      t.bigint :unit_id, null: false
      t.boolean :unit_default, default: false, null: false
      t.boolean :is_primary, default: false, null: false
      t.timestamps
    end
    add_foreign_key :unit_collection_memberships, :units, on_update: :cascade, on_delete: :cascade
    add_foreign_key :unit_collection_memberships, :collections, on_update: :cascade, on_delete: :cascade
    add_index :unit_collection_memberships, [:unit_id, :collection_id], unique: true

    unless Rails.env.test?
      execute "INSERT INTO unit_collection_memberships(unit_id, collection_id, unit_default, created_at, updated_at) "\
          "SELECT collections_units.unit_id, id, unit_default, NOW(), NOW() "\
          "FROM collections "\
          "INNER JOIN collections_units ON collections.id = collections_units.collection_id;"
      execute "INSERT INTO unit_collection_memberships(unit_id, collection_id, created_at, updated_at) "\
          "SELECT primary_unit_id, id, created_at, updated_at FROM collections "\
          "WHERE primary_unit_id IS NOT NULL;"

      results = execute "SELECT id, primary_unit_id FROM collections "\
          "WHERE primary_unit_id IS NOT NULL;"
      results.each do |row|
        execute "UPDATE unit_collection_memberships "\
            "SET is_primary = true "\
            "WHERE unit_id = #{row['primary_unit_id']} AND collection_id = #{row['id']};"
      end
      Collection.all.select{ |c| c.title == "" }.each do |c|
        c.unit_collection_memberships.update_all(unit_default: true)
      end
    end
    rename_column :unit_collection_memberships, :is_primary, :primary

    rename_table :collections_units, :collections_units_deleteme

    rename_column :collections, :primary_unit_id, :primary_unit_id_deleteme
    rename_column :collections, :unit_default, :unit_default_deleteme
  end

  def down
    drop_table :unit_collection_memberships
    rename_table :collections_units_deleteme, :collections_units
    rename_column :collections, :primary_unit_id_deleteme, :primary_unit_id
    rename_column :collections, :unit_default_deleteme, :unit_default
  end
end
