class ChangeParentGroupToParentUnit < ActiveRecord::Migration[5.2]
  def change
    rename_column :units, :parent_group_id, :parent_unit_id
  end
end
