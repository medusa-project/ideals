class RemoveLoginsHostname < ActiveRecord::Migration[7.0]
  def change
    remove_column :logins, :hostname
  end
end
