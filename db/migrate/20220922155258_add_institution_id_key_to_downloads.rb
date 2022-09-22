class AddInstitutionIdKeyToDownloads < ActiveRecord::Migration[7.0]
  def change
    add_column :downloads, :institution_id, :bigint
    id = execute("SELECT id FROM institutions WHERE key = 'uiuc';")[0]['id']
    id = execute("SELECT id FROM institutions ORDER BY id;")[0]['id'] unless id
    execute "UPDATE downloads SET institution_id = #{id};"
    change_column_null :downloads, :institution_id, false
    add_foreign_key :downloads, :institutions, on_update: :cascade, on_delete: :cascade
    add_index :downloads, :institution_id
  end
end
