class AddBuriedColumnsToCollectionsAndUnits < ActiveRecord::Migration[7.0]
  def change
    add_column :collections, :buried, :boolean, null: false, default: false
    add_column :units, :buried, :boolean, null: false, default: false
  end
end
