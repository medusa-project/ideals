class AddRoleIdColumnToBitstreams < ActiveRecord::Migration[6.0]
  def change
    add_column :bitstreams, :role_id, :integer, null: false, default: 0
  end
end
