class RemoveGroupTypeFromCollectionGroups < ActiveRecord::Migration[5.2]
  def change
    remove_column :collection_groups, :group_type, :string
  end
end
