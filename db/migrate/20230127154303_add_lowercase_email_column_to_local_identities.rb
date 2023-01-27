class AddLowercaseEmailColumnToLocalIdentities < ActiveRecord::Migration[7.0]
  def change
    add_column :local_identities, :lowercase_email, :string
    execute "UPDATE local_identities SET lowercase_email = LOWER(email);"
    change_column_null :local_identities, :lowercase_email, false
    add_index :local_identities, :lowercase_email, unique: true
  end
end
