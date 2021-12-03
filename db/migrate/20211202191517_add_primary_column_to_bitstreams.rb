class AddPrimaryColumnToBitstreams < ActiveRecord::Migration[6.1]
  def change
    add_column :bitstreams, :primary, :boolean, default: false, null: false
    add_index :bitstreams, :primary
  end
end
