class AddInstitutionIdToImports < ActiveRecord::Migration[7.0]
  def change
    add_column :imports, :institution_id, :bigint
    id = execute("SELECT id FROM institutions WHERE key = 'uiuc';")[0]['id']
    id = execute("SELECT id FROM institutions ORDER BY id;")[0]['id'] unless id
    execute "UPDATE imports SET institution_id = #{id};"
    change_column_null :imports, :institution_id, false
    add_foreign_key :imports, :institutions, on_update: :cascade, on_delete: :cascade
    add_index :imports, :institution_id
  end
end
