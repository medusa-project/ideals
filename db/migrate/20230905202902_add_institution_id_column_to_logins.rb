class AddInstitutionIdColumnToLogins < ActiveRecord::Migration[7.0]
  def change
    add_column :logins, :institution_id, :bigint
    results = execute("SELECT id, institution_id FROM users;")
    results.each do |row|
      execute("UPDATE logins SET institution_id = #{row['institution_id']} WHERE user_id = #{row['id']};")
    end
    execute("DELETE FROM logins WHERE institution_id IS NULL;")
    change_column_null :logins, :institution_id, false
    add_foreign_key :logins, :institutions, on_update: :cascade, on_delete: :cascade
    add_index :logins, :institution_id
  end
end
