class ChangeRegisteredElementProfileForeignKeys < ActiveRecord::Migration[7.1]
  def change
    remove_foreign_key :metadata_profile_elements, :registered_elements
    add_foreign_key :metadata_profile_elements, :registered_elements, on_update: :cascade, on_delete: :restrict
    remove_foreign_key :submission_profile_elements, :registered_elements
    add_foreign_key :submission_profile_elements, :registered_elements, on_update: :cascade, on_delete: :restrict
  end
end
