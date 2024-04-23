class LengthenRegisteredElementsHighwireMappingColumn < ActiveRecord::Migration[7.1]
  def change
    change_column :registered_elements, :highwire_mapping, :string, limit: 64
  end
end
