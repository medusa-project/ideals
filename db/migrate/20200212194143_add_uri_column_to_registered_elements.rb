class AddUriColumnToRegisteredElements < ActiveRecord::Migration[6.0]
  def change
    add_column :registered_elements, :uri, :string
    add_index :registered_elements, :uri, unique: true
  end
end
