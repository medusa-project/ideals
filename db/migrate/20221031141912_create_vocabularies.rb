class CreateVocabularies < ActiveRecord::Migration[7.0]
  def change
    create_table :vocabularies do |t|
      t.bigint :institution_id, null: false
      t.string :key, null: false
      t.string :name, null: false

      t.timestamps
    end
    add_foreign_key :vocabularies, :institutions,
                    on_update: :cascade, on_delete: :cascade
    add_index :vocabularies, [:institution_id, :key], unique: true
    add_index :vocabularies, [:institution_id, :name], unique: true

    unless Rails.env.test?
      institution_ids = execute("SELECT id FROM institutions;").map{ |a| a['id'] }

      institution_ids.each do |id|
        execute "INSERT INTO vocabularies(institution_id, key, name, created_at, updated_at) VALUES
                 (#{id}, 'common_genres', 'Common Genres', NOW(), NOW()),
                 (#{id}, 'common_iso_languages', 'Common ISO Languages', NOW(), NOW()),
                 (#{id}, 'common_types', 'Common Types', NOW(), NOW()),
                 (#{id}, 'degree_names', 'Degree Names', NOW(), NOW()),
                 (#{id}, 'dissertation_thesis', 'Dissertation Thesis', NOW(), NOW());"
      end
    end
  end
end
