class RenameUsersTypeColumnToAuthMethod < ActiveRecord::Migration[7.0]
  def change
    add_column :users, :auth_method, :integer
    execute "UPDATE users SET auth_method = 0 WHERE type = 'LocalUser';"
    execute "UPDATE users SET auth_method = 1 WHERE type = 'ShibbolethUser';"
    execute "UPDATE users SET auth_method = 2 WHERE type = 'SamlUser';"
    change_column_null :users, :auth_method, false
    remove_column :users, :type
  end
end
