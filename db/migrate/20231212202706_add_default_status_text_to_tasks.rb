class AddDefaultStatusTextToTasks < ActiveRecord::Migration[7.1]
  def change
    change_column_default :tasks, :status_text, "Waiting..."
  end
end
