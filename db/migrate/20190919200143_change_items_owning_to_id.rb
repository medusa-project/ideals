class ChangeItemsOwningToId < ActiveRecord::Migration[5.2]
  def change
    rename_column :items, :collection_id, :collection_id
  end
end
