class AddIndexOnTasksCreatedAt < ActiveRecord::Migration[7.0]
  def change
    add_index :tasks, :created_at
  end
end
