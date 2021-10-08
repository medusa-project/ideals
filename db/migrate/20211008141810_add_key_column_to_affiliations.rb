class AddKeyColumnToAffiliations < ActiveRecord::Migration[6.0]
  def change
    add_column :affiliations, :key, :string
    execute "UPDATE affiliations SET key = 'staff' WHERE id = 1;"
    execute "UPDATE affiliations SET key = 'grad' WHERE id = 2;"
    execute "UPDATE affiliations SET key = 'phd' WHERE id = 3;"
    execute "UPDATE affiliations SET key = 'masters' WHERE id = 4;"
    execute "UPDATE affiliations SET key = 'undergrad' WHERE id = 5;"
    change_column_null :affiliations, :key, false
    add_index :affiliations, :key, unique: true
  end
end
