class AddCollectionsUnitsJoinTable < ActiveRecord::Migration[6.0]
  def change
    create_join_table :collections, :units
  end
end
