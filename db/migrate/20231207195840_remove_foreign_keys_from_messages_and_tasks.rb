class RemoveForeignKeysFromMessagesAndTasks < ActiveRecord::Migration[7.1]
  def change
    remove_foreign_key :messages, :bitstreams
    remove_foreign_key :downloads, :tasks
    remove_foreign_key :users, :tasks
  end
end
