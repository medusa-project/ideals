class ChangeCollectionGroupIdToUnitId < ActiveRecord::Migration[5.2]
  def change
    rename_column :collections, :collection_group_id, :unit_id
  end
end
