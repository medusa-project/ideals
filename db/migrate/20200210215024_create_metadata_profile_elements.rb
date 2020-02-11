class CreateMetadataProfileElements < ActiveRecord::Migration[6.0]
  def change
    create_table :metadata_profile_elements do |t|
      t.bigint :metadata_profile_id, null: false
      t.bigint :registered_element_id, null: false
      t.integer :index, null: false
      t.string :label, null: false
      t.boolean :visible, null: false, default: true
      t.boolean :facetable, null: false, default: false
      t.boolean :searchable, null: false, default: false
      t.boolean :sortable, null: false, default: false
      t.boolean :repeatable, null: false, default: true
      t.boolean :required, null: false, default: false

      t.timestamps
    end
    add_foreign_key :metadata_profile_elements, :metadata_profiles,
                    on_update: :cascade, on_delete: :cascade
    add_foreign_key :metadata_profile_elements, :registered_elements,
                    on_update: :cascade, on_delete: :restrict
    add_index :metadata_profile_elements, :index
    add_index :metadata_profile_elements, :visible
    add_index :metadata_profile_elements, :facetable
    add_index :metadata_profile_elements, :searchable
    add_index :metadata_profile_elements, :sortable
    add_index :metadata_profile_elements, :required
  end
end
