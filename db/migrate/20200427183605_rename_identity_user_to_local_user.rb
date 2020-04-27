class RenameIdentityUserToLocalUser < ActiveRecord::Migration[6.0]
  def change
    execute "UPDATE users SET type = 'LocalUser' WHERE type = 'IdentityUser';"
  end
end
