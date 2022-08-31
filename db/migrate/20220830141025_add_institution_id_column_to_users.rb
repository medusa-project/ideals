class AddInstitutionIdColumnToUsers < ActiveRecord::Migration[7.0]
  def up
    add_column :users, :institution_id, :bigint
    id = execute("SELECT id FROM institutions WHERE key = 'uiuc';")[0]['id']
    execute "UPDATE users SET institution_id = #{id} WHERE email LIKE '%illinois.edu' OR email LIKE '%uiuc.edu';"

    add_foreign_key :users, :institutions, on_update: :cascade,
                    on_delete: :restrict
    add_index :users, :institution_id
  end
  def down
    remove_column :users, :institution_id
  end
end
