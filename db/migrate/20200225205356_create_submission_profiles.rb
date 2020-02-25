class CreateSubmissionProfiles < ActiveRecord::Migration[6.0]
  def change
    create_table :submission_profiles do |t|
      t.string :name, null: false
      t.boolean :default, null: false, default: false

      t.timestamps
    end
    add_index :submission_profiles, :name, unique: true
    add_index :submission_profiles, :default

    add_column :collections, :submission_profile_id, :bigint
    add_foreign_key :collections, :submission_profiles,
                    on_update: :cascade, on_delete: :restrict
  end
end
