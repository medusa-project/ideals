class RenameBitstreamsRoleIdColumnToRole < ActiveRecord::Migration[6.0]
  def change
    rename_column :bitstreams, :role_id, :role
  end
end
