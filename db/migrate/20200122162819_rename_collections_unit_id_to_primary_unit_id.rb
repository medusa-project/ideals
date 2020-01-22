class RenameCollectionsUnitIdToPrimaryUnitId < ActiveRecord::Migration[6.0]
  def change
    rename_column :collections, :unit_id, :primary_unit_id
  end
end
