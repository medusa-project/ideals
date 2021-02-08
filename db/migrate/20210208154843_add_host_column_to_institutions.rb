class AddHostColumnToInstitutions < ActiveRecord::Migration[6.0]
  def up
    add_column :institutions, :fqdn, :string
    execute "UPDATE institutions SET fqdn = key;"
    change_column_null :institutions, :fqdn, false
    add_index :institutions, :fqdn, unique: true
  end
  def down
    remove_column :institutions, :fqdn
  end
end
