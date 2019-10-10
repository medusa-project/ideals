class AddGroupToCollection < ActiveRecord::Migration[5.2]
  def change
    add_column :collections, :collection_group_id, :integer
  end
end
