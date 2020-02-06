class AddUniqueKeyOnCollectionUnitRelationships < ActiveRecord::Migration[6.0]
  def change
    add_index :collection_unit_relationships, [:unit_id, :collection_id], unique: true,
              name: "index_curs_on_unit_id_and_collection_id"
  end
end
