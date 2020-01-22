class AddCollectionsItemsJoinTable < ActiveRecord::Migration[6.0]
  def change
    create_join_table :collections, :items
  end
end
