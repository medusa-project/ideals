class RemoveMetadataProfileIdColumnFromUnits < ActiveRecord::Migration[7.1]
  def change
    remove_column :units, :metadata_profile_id
  end
end
