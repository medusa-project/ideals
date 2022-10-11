class AddServiceNameColumnToInstitutions < ActiveRecord::Migration[7.0]
  def change
    add_column :institutions, :service_name, :string
    execute "UPDATE institutions SET service_name = 'IDEALS';"
    change_column_null :institutions, :service_name, false
  end
end
