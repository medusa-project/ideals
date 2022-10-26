class AddUniqueIndexOnRegisteredElementsInstitutionIdAndUri < ActiveRecord::Migration[7.0]
  def up
    execute "UPDATE registered_elements SET uri = null WHERE uri = '';"
    add_index :registered_elements, [:institution_id, :uri], unique: true
  end
  def down
    remove_index :registered_elements, [:institution_id, :uri]
  end
end
