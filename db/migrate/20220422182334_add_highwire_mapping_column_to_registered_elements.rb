class AddHighwireMappingColumnToRegisteredElements < ActiveRecord::Migration[7.0]
  def change
    add_column :registered_elements, :highwire_mapping, :string
  end
end
