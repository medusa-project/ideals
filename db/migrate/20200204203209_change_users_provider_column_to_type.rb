class ChangeUsersProviderColumnToType < ActiveRecord::Migration[6.0]
  def change
    add_column :users, :type, :string
    execute "update users set type = 'IdentityUser' where provider = 'identity';"
    execute "update users set type = 'ShibbolethUser' where provider = 'shibboleth';"
    remove_column :users, :provider
  end
end
