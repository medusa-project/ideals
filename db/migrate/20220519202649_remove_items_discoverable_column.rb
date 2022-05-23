class RemoveItemsDiscoverableColumn < ActiveRecord::Migration[7.0]
  def change
    remove_column :items, :discoverable
  end
end
