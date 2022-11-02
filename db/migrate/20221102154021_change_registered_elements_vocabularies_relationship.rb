class ChangeRegisteredElementsVocabulariesRelationship < ActiveRecord::Migration[7.0]
  def change
    add_column :registered_elements, :vocabulary_id, :bigint

    unless Rails.env.test?
      institution_ids = execute("SELECT id FROM institutions;").map{ |r| r['id'] }
      institution_ids.each do |institution_id|
        common_genres_id        = execute("SELECT id FROM vocabularies
                                           WHERE institution_id = #{institution_id}
                                               AND key = 'common_genres';")[0]['id']
        common_iso_languages_id = execute("SELECT id FROM vocabularies
                                           WHERE institution_id = #{institution_id}
                                               AND key = 'common_iso_languages';")[0]['id']
        common_types_id         = execute("SELECT id FROM vocabularies
                                           WHERE institution_id = #{institution_id}
                                               AND key = 'common_types';")[0]['id']
        degree_names_id         = execute("SELECT id FROM vocabularies
                                           WHERE institution_id = #{institution_id}
                                               AND key = 'degree_names';")[0]['id']
        dissertation_thesis_id  = execute("SELECT id FROM vocabularies
                                           WHERE institution_id = #{institution_id}
                                               AND key = 'dissertation_thesis';")[0]['id']

        execute("UPDATE registered_elements SET vocabulary_id = #{common_genres_id}
                 WHERE vocabulary_key = 'common_genres'
                     AND institution_id = #{institution_id};") if common_genres_id
        execute("UPDATE registered_elements SET vocabulary_id = #{common_iso_languages_id}
                 WHERE vocabulary_key = 'common_iso_languages'
                     AND institution_id = #{institution_id};") if common_iso_languages_id
        execute("UPDATE registered_elements SET vocabulary_id = #{common_types_id}
                 WHERE vocabulary_key = 'common_types'
                     AND institution_id = #{institution_id};") if common_types_id
        execute("UPDATE registered_elements SET vocabulary_id = #{degree_names_id}
                 WHERE vocabulary_key = 'degree_names'
                     AND institution_id = #{institution_id};") if degree_names_id
        execute("UPDATE registered_elements SET vocabulary_id = #{dissertation_thesis_id}
                 WHERE vocabulary_key = 'dissertation_thesis'
                     AND institution_id = #{institution_id};") if dissertation_thesis_id
      end
    end

    add_foreign_key :registered_elements, :vocabularies,
                    on_update: :cascade, on_delete: :restrict
    add_index :registered_elements, :vocabulary_id
    remove_column :registered_elements, :vocabulary_key
    remove_column :vocabularies, :key
  end
end
