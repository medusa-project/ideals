class RemoveEventsTempStatIdColumn < ActiveRecord::Migration[7.0]
  def change
    remove_column :events, :temp_stat_id
  end
end
