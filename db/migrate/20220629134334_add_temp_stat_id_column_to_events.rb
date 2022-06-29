class AddTempStatIdColumnToEvents < ActiveRecord::Migration[7.0]
  def change
    add_column :events, :temp_stat_id, :integer, null: true
    add_index :events, :temp_stat_id
  end
end
