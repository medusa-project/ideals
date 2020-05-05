class AddNameColumnToLocalIdentities < ActiveRecord::Migration[6.0]
  def change
    add_column :local_identities, :name, :string
    execute "UPDATE local_identities SET name = email;"
    change_column_null :local_identities, :name, false
  end
end
