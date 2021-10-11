class MoveVocabularyKeyColumn < ActiveRecord::Migration[6.0]
  def change
    add_column :registered_elements, :vocabulary_key, :string
    execute "UPDATE registered_elements SET vocabulary_key = 'degree_names' WHERE name = 'dc:identifier';"
    execute "UPDATE registered_elements SET vocabulary_key = 'common_iso_languages' WHERE name = 'dc:language';"
    execute "UPDATE registered_elements SET vocabulary_key = 'common_types' WHERE name = 'dc:type';"
    execute "UPDATE registered_elements SET vocabulary_key = 'common_genres' WHERE name = 'dc:type:genre';"
    execute "UPDATE registered_elements SET vocabulary_key = 'dissertation_thesis' WHERE name = 'thesis:degree:level';"

    remove_column :submission_profile_elements, :vocabulary_key
  end
end
