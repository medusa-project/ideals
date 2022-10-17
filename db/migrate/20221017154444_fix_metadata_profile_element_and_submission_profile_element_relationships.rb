class FixMetadataProfileElementAndSubmissionProfileElementRelationships < ActiveRecord::Migration[7.0]
  def up
    # Metadata profile elements
    results = execute("SELECT mpe.id AS mpe_id, re.name AS re_name,
                           mp.institution_id AS mp_institution_id,
                           re.institution_id AS re_institution_id
                       FROM metadata_profile_elements mpe
                       LEFT JOIN registered_elements re ON mpe.registered_element_id = re.id
                       LEFT JOIN metadata_profiles mp ON mpe.metadata_profile_id = mp.id
                       WHERE mp.institution_id != re.institution_id;")
    results.each do |row|
      reg_e_id = execute("SELECT id
                          FROM registered_elements
                          WHERE name = '#{row['re_name']}'
                              AND institution_id = #{row['mp_institution_id']};")[0]['id']
      update_sql = "UPDATE metadata_profile_elements
                    SET registered_element_id = #{reg_e_id}
                    WHERE id = #{row['mpe_id']};"
      execute(update_sql)
    end

    # Submission profile elements
    results = execute("SELECT spe.id AS spe_id, re.name AS re_name,
                           sp.institution_id AS sp_institution_id,
                           re.institution_id AS re_institution_id
                       FROM submission_profile_elements spe
                       LEFT JOIN registered_elements re ON spe.registered_element_id = re.id
                       LEFT JOIN submission_profiles sp ON spe.submission_profile_id = sp.id
                       WHERE sp.institution_id != re.institution_id;")
    results.each do |row|
      reg_e_id = execute("SELECT id
                          FROM registered_elements
                          WHERE name = '#{row['re_name']}'
                              AND institution_id = #{row['sp_institution_id']};")[0]['id']
      update_sql = "UPDATE submission_profile_elements
                    SET registered_element_id = #{reg_e_id}
                    WHERE id = #{row['spe_id']};"
      execute(update_sql)
    end
  end

  def down
  end
end
