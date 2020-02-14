class AddSysadminColumnToUsers < ActiveRecord::Migration[6.0]
  def change
    add_column :users, :sysadmin, :boolean, null: false, default: false
  end
end
