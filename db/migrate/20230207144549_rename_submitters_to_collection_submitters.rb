class RenameSubmittersToCollectionSubmitters < ActiveRecord::Migration[7.0]
  def change
    rename_table :submitters, :collection_submitters
  end
end
