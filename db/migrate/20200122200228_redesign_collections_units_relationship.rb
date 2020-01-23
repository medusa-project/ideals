class RedesignCollectionsUnitsRelationship < ActiveRecord::Migration[6.0]
  def change
    drop_table :collections_units
    remove_column :collections, :primary_unit_id
    create_table :collection_unit_relationships do |t|
      t.integer :collection_id
      t.integer :unit_id
      t.boolean :primary, null: false, default: false
      t.timestamps
    end
    add_index :collection_unit_relationships, [:id, :primary]
    add_foreign_key :collection_unit_relationships, :collections
    add_foreign_key :collection_unit_relationships, :units
  end
end
