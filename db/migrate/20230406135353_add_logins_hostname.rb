class AddLoginsHostname < ActiveRecord::Migration[7.0]
  def change
    add_column :logins, :hostname, :string
  end
end
