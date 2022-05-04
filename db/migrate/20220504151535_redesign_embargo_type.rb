class RedesignEmbargoType < ActiveRecord::Migration[7.0]
  def change
    add_column :embargoes, :kind, :integer, null: true
    execute "UPDATE embargoes SET kind = 0 WHERE full_access = true;"
    execute "UPDATE embargoes SET kind = 1 WHERE download = true;"
    change_column_null :embargoes, :kind, false
    remove_column :embargoes, :download
    remove_column :embargoes, :full_access
  end
end
