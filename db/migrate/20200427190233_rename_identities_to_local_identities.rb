class RenameIdentitiesToLocalIdentities < ActiveRecord::Migration[6.0]
  def change
    rename_table :identities, :local_identities
  end
end
