class AddDefaultColumnToInstitutions < ActiveRecord::Migration[6.0]
  def change
    add_column :institutions, :default, :boolean, default: false, null: false
    add_index :institutions, :default
  end
end
