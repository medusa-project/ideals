class AddInstitutionIdColumnsToMetadataModels < ActiveRecord::Migration[6.0]
  def change
    result = execute "SELECT id FROM institutions WHERE key = 'uiuc';"
    institution_id = result[0]['id']

    add_column :registered_elements, :institution_id, :bigint
    execute "UPDATE registered_elements SET institution_id = #{institution_id};"
    change_column_null :registered_elements, :institution_id, false

    add_column :metadata_profiles, :institution_id, :bigint
    execute "UPDATE metadata_profiles SET institution_id = #{institution_id};"
    change_column_null :metadata_profiles, :institution_id, false

    add_column :submission_profiles, :institution_id, :bigint
    execute "UPDATE submission_profiles SET institution_id = #{institution_id};"
    change_column_null :submission_profiles, :institution_id, false
  end
end
