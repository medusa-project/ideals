class AddMetadataProfileIdColumnToUnits < ActiveRecord::Migration[7.0]
  def change
    add_column :units, :metadata_profile_id, :bigint, null: true
    add_foreign_key :units, :metadata_profiles, on_update: :cascade, on_delete: :restrict
    add_index :units, :metadata_profile_id
  end
end
