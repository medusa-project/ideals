class RenameSubmissionProfilesDefaultToInstitutionDefault < ActiveRecord::Migration[7.0]
  def change
    rename_column :submission_profiles, :default, :institution_default
  end
end
