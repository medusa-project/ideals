class ChangeUniquenessConstraintsOnRegisteredElements < ActiveRecord::Migration[7.0]
  def change
    remove_index :registered_elements, :name
    remove_index :registered_elements, :uri
    add_index :registered_elements, [:name, :institution_id], unique: true
    add_index :registered_elements, [:uri, :institution_id], unique: true
  end
end
