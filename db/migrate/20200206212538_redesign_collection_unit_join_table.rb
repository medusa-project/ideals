class RedesignCollectionUnitJoinTable < ActiveRecord::Migration[6.0]
  def up
    drop_table :collection_unit_relationships
    create_join_table :collections, :units
    add_foreign_key :collections_units, :collections,
                    on_update: :cascade, on_delete: :restrict
    add_foreign_key :collections_units, :units,
                    on_update: :cascade, on_delete: :cascade
    add_index :collections_units, [:collection_id, :unit_id], unique: true
    add_column :collections, :primary_unit_id, :bigint
    add_foreign_key :collections, :units, column: :primary_unit_id,
                    on_update: :cascade, on_delete: :restrict
  end
  def down
    drop_table :collections_units
    create_table :collection_unit_relationships do |t|
      t.timestamps
    end
    remove_column :collections, :primary_unit_id
  end
end
