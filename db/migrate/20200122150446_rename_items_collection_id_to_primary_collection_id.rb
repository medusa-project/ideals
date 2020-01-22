class RenameItemsCollectionIdToPrimaryCollectionId < ActiveRecord::Migration[6.0]
  def change
    rename_column :items, :collection_id, :primary_collection_id
  end
end
