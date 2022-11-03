class RedesignImportsToUseTasks < ActiveRecord::Migration[7.0]
  def up
    remove_column :imports, :percent_complete
    remove_column :imports, :status
    remove_column :imports, :last_error_message
    add_column :imports, :task_id, :bigint
    add_foreign_key :imports, :tasks, on_update: :cascade, on_delete: :restrict
    add_index :imports, :task_id, unique: true
  end
  def down
    add_column :imports, :percent_complete, :float
    add_column :imports, :status, :integer
    add_column :imports, :last_error_message, :text
    remove_column :imports, :task_id
  end
end
