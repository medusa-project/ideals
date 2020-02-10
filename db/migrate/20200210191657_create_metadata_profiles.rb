class CreateMetadataProfiles < ActiveRecord::Migration[6.0]
  def change
    create_table :metadata_profiles do |t|
      t.string :name, null: false
      t.boolean :default, default: false, null: false

      t.timestamps
    end
    add_index :metadata_profiles, :name, unique: true
    add_index :metadata_profiles, :default
    add_column :collections, :metadata_profile_id, :bigint
    add_foreign_key :collections, :metadata_profiles,
                    on_update: :cascade, on_delete: :restrict
  end
end
