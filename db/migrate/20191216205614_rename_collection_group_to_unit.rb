class RenameCollectionGroupToUnit < ActiveRecord::Migration[5.2]
  def change
    rename_table :collection_groups, :units
  end
end
