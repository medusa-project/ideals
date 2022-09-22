class AddInstitutionIdColumnToTasks < ActiveRecord::Migration[7.0]
  def change
    add_column :tasks, :institution_id, :bigint
    results = execute("SELECT id FROM institutions WHERE key = 'uiuc';")
    if results.any?
      id = results[0]['id']
    else
      id = execute("SELECT id FROM institutions ORDER BY id;")[0]['id']
    end
    execute "UPDATE tasks SET institution_id = #{id};"
    change_column_null :tasks, :institution_id, false
    add_foreign_key :tasks, :institutions, on_update: :cascade, on_delete: :cascade
    add_index :tasks, :institution_id
  end
end
