class AddJobIdAndQueueColumnsToTasks < ActiveRecord::Migration[7.1]
  def change
    add_column :tasks, :job_id, :string
    add_index :tasks, :job_id, unique: true

    add_column :tasks, :queue, :string
    add_index :tasks, :queue
  end
end
