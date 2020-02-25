class CreateSubmissionProfileElements < ActiveRecord::Migration[6.0]
  def change
    create_table :submission_profile_elements do |t|
      t.bigint :submission_profile_id, null: false
      t.bigint :registered_element_id, null: false
      t.integer :index, null: false
      t.string :label
      t.text :help_text
      t.boolean :repeatable, null: false, default: false
      t.boolean :required, null: false, default: true
      t.timestamps
    end
    add_index :submission_profile_elements, :index
    add_index :submission_profile_elements, :repeatable
    add_index :submission_profile_elements, :required
    add_foreign_key :submission_profile_elements, :submission_profiles,
                    on_update: :cascade, on_delete: :cascade
    add_foreign_key :submission_profile_elements, :registered_elements,
                    on_update: :cascade, on_delete: :restrict
  end
end
