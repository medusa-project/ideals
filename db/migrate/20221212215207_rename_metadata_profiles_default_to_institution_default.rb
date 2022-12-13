class RenameMetadataProfilesDefaultToInstitutionDefault < ActiveRecord::Migration[7.0]
  def change
    rename_column :metadata_profiles, :default, :institution_default
  end
end
