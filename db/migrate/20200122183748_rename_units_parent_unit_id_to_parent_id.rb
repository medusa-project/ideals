class RenameUnitsParentUnitIdToParentId < ActiveRecord::Migration[6.0]
  def change
    rename_column :units, :parent_unit_id, :parent_id
  end
end
