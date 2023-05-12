class RemoveUsersAuthMethodColumn < ActiveRecord::Migration[7.0]
  def change
    remove_column :users, :auth_method
  end
end
