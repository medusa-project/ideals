class RemoveGroupIdFromCollectionGroup < ActiveRecord::Migration[5.2]
  def change
    remove_column :collection_groups, :group_id, :integer
  end
end
