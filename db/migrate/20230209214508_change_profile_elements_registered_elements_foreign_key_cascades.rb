class ChangeProfileElementsRegisteredElementsForeignKeyCascades < ActiveRecord::Migration[7.0]
  def change
    remove_foreign_key :metadata_profile_elements, :registered_elements
    remove_foreign_key :submission_profile_elements, :registered_elements
    add_foreign_key :metadata_profile_elements, :registered_elements,
                    on_update: :cascade, on_delete: :cascade
    add_foreign_key :submission_profile_elements, :registered_elements,
                    on_update: :cascade, on_delete: :cascade
  end
end
