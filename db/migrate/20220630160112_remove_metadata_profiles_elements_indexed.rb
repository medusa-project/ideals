class RemoveMetadataProfilesElementsIndexed < ActiveRecord::Migration[7.0]
  def change
    remove_column :metadata_profile_elements, :indexed
  end
end
