class ChangeUniquenessConstraintsOnProfiles < ActiveRecord::Migration[7.0]
  def change
    remove_index :metadata_profiles, :name
    add_index :metadata_profiles, [:institution_id, :name], unique: true

    remove_index :submission_profiles, :name
    add_index :submission_profiles, [:institution_id, :name], unique: true
  end
end
