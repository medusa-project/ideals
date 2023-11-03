class RenameLocalIdentitiesToCredentials < ActiveRecord::Migration[7.1]
  def change
    rename_table :local_identities, :credentials
  end
end
