class RenameLoginsAuthMethodToProvider < ActiveRecord::Migration[7.0]
  def change
    rename_column :logins, :auth_method, :provider
  end
end
