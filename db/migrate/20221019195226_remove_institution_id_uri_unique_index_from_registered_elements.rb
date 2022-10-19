class RemoveInstitutionIdUriUniqueIndexFromRegisteredElements < ActiveRecord::Migration[7.0]
  def change
    remove_index :registered_elements, [:uri, :institution_id]
  end
end
