class RemoveNameColumnFromLocalIdentities < ActiveRecord::Migration[6.0]
  def change
    remove_column :local_identities, :name
  end
end
