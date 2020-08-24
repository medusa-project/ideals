class CreateMedusaIngests < ActiveRecord::Migration[6.0]
  def change
    create_table :medusa_ingests do |t|
      t.string :ideals_class, null: false
      t.string :ideals_identifier, null: false
      t.string :staging_key, null: false
      t.string :target_key, null: false
      t.string :staging_path
      t.string :request_status
      t.string :medusa_path
      t.string :medusa_uuid
      t.datetime :response_time
      t.string :error_text
      t.timestamps
    end
    add_index :medusa_ingests, :medusa_uuid, unique: true
    add_index :medusa_ingests, :staging_key, unique: true
    add_index :medusa_ingests, :target_key, unique: true
  end
end
