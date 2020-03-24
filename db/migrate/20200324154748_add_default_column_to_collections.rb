class AddDefaultColumnToCollections < ActiveRecord::Migration[6.0]
  def change
    add_column :collections, :unit_default, :boolean, default: false, null: false
  end
end
