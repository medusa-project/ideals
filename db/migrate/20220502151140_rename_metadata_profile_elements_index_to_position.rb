class RenameMetadataProfileElementsIndexToPosition < ActiveRecord::Migration[7.0]
  def change
    rename_column :metadata_profile_elements, :index, :position
  end
end
