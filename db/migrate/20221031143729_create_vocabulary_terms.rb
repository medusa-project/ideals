class CreateVocabularyTerms < ActiveRecord::Migration[7.0]
  def change
    create_table :vocabulary_terms do |t|
      t.bigint :vocabulary_id, null: false
      t.string :stored_value, null: false
      t.string :displayed_value, null: false

      t.timestamps
    end
    add_index :vocabulary_terms, :vocabulary_id
    add_foreign_key :vocabulary_terms, :vocabularies,
                    on_update: :cascade, on_delete: :cascade
    add_index :vocabulary_terms, [:vocabulary_id, :stored_value], unique: true
    add_index :vocabulary_terms, [:vocabulary_id, :displayed_value], unique: true

    unless Rails.env.test?
      vocab_ids = execute("SELECT id FROM vocabularies WHERE key = 'common_genres';").map{ |a| a['id'] }
      vocab_ids.each do |vocab_id|
        execute "INSERT INTO vocabulary_terms(vocabulary_id, stored_value, displayed_value, created_at, updated_at) VALUES
                 (#{vocab_id}, 'article', 'Article', NOW(), NOW()),
                 (#{vocab_id}, 'bibliography', 'Bibliography', NOW(), NOW()),
                 (#{vocab_id}, 'book', 'Book', NOW(), NOW()),
                 (#{vocab_id}, 'book chapter', 'Book Chapter', NOW(), NOW()),
                 (#{vocab_id}, 'book review', 'Book Review', NOW(), NOW()),
                 (#{vocab_id}, 'editorial', 'Editorial', NOW(), NOW()),
                 (#{vocab_id}, 'essay', 'Essay', NOW(), NOW()),
                 (#{vocab_id}, 'conference paper', 'Conference Paper / Presentation', NOW(), NOW()),
                 (#{vocab_id}, 'conference poster', 'Conference Poster', NOW(), NOW()),
                 (#{vocab_id}, 'conference proceeding', 'Conference Proceeding (whole)', NOW(), NOW()),
                 (#{vocab_id}, 'data', 'Data', NOW(), NOW()),
                 (#{vocab_id}, 'dissertation/thesis', 'Dissertation / Thesis', NOW(), NOW()),
                 (#{vocab_id}, 'drawing', 'Drawing', NOW(), NOW()),
                 (#{vocab_id}, 'fiction', 'Fiction', NOW(), NOW()),
                 (#{vocab_id}, 'journal', 'Journal (whole)', NOW(), NOW()),
                 (#{vocab_id}, 'newsletter', 'Newsletter', NOW(), NOW()),
                 (#{vocab_id}, 'performance', 'Performance', NOW(), NOW()),
                 (#{vocab_id}, 'photograph', 'Photograph', NOW(), NOW()),
                 (#{vocab_id}, 'poetry', 'Poetry', NOW(), NOW()),
                 (#{vocab_id}, 'presentation/lecture/speech', 'Presentation / Lecture / Speech', NOW(), NOW()),
                 (#{vocab_id}, 'proposal', 'Proposal', NOW(), NOW()),
                 (#{vocab_id}, 'oral history', 'Oral history', NOW(), NOW()),
                 (#{vocab_id}, 'report', 'Report (Grant or Annual)', NOW(), NOW()),
                 (#{vocab_id}, 'score', 'Score', NOW(), NOW()),
                 (#{vocab_id}, 'technical report', 'Technical Report', NOW(), NOW()),
                 (#{vocab_id}, 'website', 'Website', NOW(), NOW()),
                 (#{vocab_id}, 'working paper', 'Working / Discussion Paper', NOW(), NOW()),
                 (#{vocab_id}, 'other', 'Other', NOW(), NOW());"
      end

      vocab_ids = execute("SELECT id FROM vocabularies WHERE key = 'common_iso_languages';").map{ |a| a['id'] }
      vocab_ids.each do |vocab_id|
        execute "INSERT INTO vocabulary_terms(vocabulary_id, stored_value, displayed_value, created_at, updated_at) VALUES
                 (#{vocab_id}, 'en', 'English', NOW(), NOW()),
                 (#{vocab_id}, 'zh', 'Chinese', NOW(), NOW()),
                 (#{vocab_id}, 'fr', 'French', NOW(), NOW()),
                 (#{vocab_id}, 'de', 'German', NOW(), NOW()),
                 (#{vocab_id}, 'it', 'Italian', NOW(), NOW()),
                 (#{vocab_id}, 'ja', 'Japanese', NOW(), NOW()),
                 (#{vocab_id}, 'es', 'Spanish', NOW(), NOW()),
                 (#{vocab_id}, 'tr', 'Turkish', NOW(), NOW()),
                 (#{vocab_id}, 'other', 'Other', NOW(), NOW());"
      end

      vocab_ids = execute("SELECT id FROM vocabularies WHERE key = 'common_types';").map{ |a| a['id'] }
      vocab_ids.each do |vocab_id|
        execute "INSERT INTO vocabulary_terms(vocabulary_id, stored_value, displayed_value, created_at, updated_at) VALUES
                 (#{vocab_id}, 'sound', 'Audio', NOW(), NOW()),
                 (#{vocab_id}, 'dataset', 'Dataset / Spreadsheet', NOW(), NOW()),
                 (#{vocab_id}, 'still image', 'Image', NOW(), NOW()),
                 (#{vocab_id}, 'text', 'Text', NOW(), NOW()),
                 (#{vocab_id}, 'moving image', 'Video', NOW(), NOW()),
                 (#{vocab_id}, 'other', 'Other', NOW(), NOW());"
      end
      vocab_ids = execute("SELECT id FROM vocabularies WHERE key = 'degree_names';").map{ |a| a['id'] }
      vocab_ids.each do |vocab_id|
        execute "INSERT INTO vocabulary_terms(vocabulary_id, stored_value, displayed_value, created_at, updated_at) VALUES
                 (#{vocab_id}, 'B.A. (bachelor''s)', 'B.A. (bachelor''s)', NOW(), NOW()),
                 (#{vocab_id}, 'B.S. (bachelor''s)', 'B.S. (bachelor''s)', NOW(), NOW()),
                 (#{vocab_id}, 'M.A. (master''s)', 'M.A. (master''s)', NOW(), NOW()),
                 (#{vocab_id}, 'M.Arch. (master''s)', 'M.Arch. (master''s)', NOW(), NOW()),
                 (#{vocab_id}, 'M.F.A. (master''s)', 'M.F.A. (master''s)', NOW(), NOW()),
                 (#{vocab_id}, 'M.H.R.I.R. (master''s)', 'M.H.R.I.R. (master''s)', NOW(), NOW()),
                 (#{vocab_id}, 'M.L.A. (master''s)', 'M.L.A. (master''s)', NOW(), NOW()),
                 (#{vocab_id}, 'M.Mus. (master''s)', 'M.Mus. (master''s)', NOW(), NOW()),
                 (#{vocab_id}, 'M.S. (master''s)','M.S. (master''s)', NOW(), NOW()),
                 (#{vocab_id}, 'M.S.P.H. (master''s)', 'M.S.P.H. (master''s)', NOW(), NOW()),
                 (#{vocab_id}, 'M.U.P. (master''s)','M.U.P. (master''s)', NOW(), NOW()),
                 (#{vocab_id}, 'A.Mus.D. (doctoral)', 'A.Mus.D. (doctoral)', NOW(), NOW()),
                 (#{vocab_id}, 'Au.D. (doctoral)', 'Au.D. (doctoral)', NOW(), NOW()),
                 (#{vocab_id}, 'Ed.D. (doctoral)', 'Ed.D. (doctoral)', NOW(), NOW()),
                 (#{vocab_id}, 'J.S.D. (doctoral)', 'J.S.D. (doctoral)', NOW(), NOW()),
                 (#{vocab_id}, 'Ph.D. (doctoral)', 'Ph.D. (doctoral)', NOW(), NOW());"
      end

      vocab_ids = execute("SELECT id FROM vocabularies WHERE key = 'dissertation_thesis';").map{ |a| a['id'] }
      vocab_ids.each do |vocab_id|
        execute "INSERT INTO vocabulary_terms(vocabulary_id, stored_value, displayed_value, created_at, updated_at) VALUES
                 (#{vocab_id}, 'Dissertation', 'Dissertation (Doctoral level only)', NOW(), NOW()),
                 (#{vocab_id}, 'Thesis', 'Thesis (Bachelor''s or Master''s level)', NOW(), NOW());"
      end
    end
  end
end
