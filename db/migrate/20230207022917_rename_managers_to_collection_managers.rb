class RenameManagersToCollectionManagers < ActiveRecord::Migration[7.0]
  def change
    rename_table :managers, :collection_managers
  end
end
