class AddRegisteredElementsInstitutionsForeignKey < ActiveRecord::Migration[7.0]
  def change
    add_foreign_key :registered_elements, :institutions, on_update: :cascade, on_delete: :cascade
  end
end
