class AddAuthHashColumnToUsers < ActiveRecord::Migration[7.0]
  def change
    add_column :users, :auth_hash, :text
  end
end
