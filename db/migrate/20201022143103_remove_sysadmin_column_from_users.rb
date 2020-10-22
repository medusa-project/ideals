class RemoveSysadminColumnFromUsers < ActiveRecord::Migration[6.0]
  def change
    remove_column :users, :sysadmin
  end
end
