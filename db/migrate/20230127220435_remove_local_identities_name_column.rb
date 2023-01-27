class RemoveLocalIdentitiesNameColumn < ActiveRecord::Migration[7.0]
  def change
    remove_column :local_identities, :name
  end
end
