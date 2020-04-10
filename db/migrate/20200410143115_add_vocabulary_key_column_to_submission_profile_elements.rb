class AddVocabularyKeyColumnToSubmissionProfileElements < ActiveRecord::Migration[6.0]
  def change
    add_column :submission_profile_elements, :vocabulary_key, :string
  end
end
