class AddHappenedAtColumnToEvents < ActiveRecord::Migration[6.0]
  def up
    add_column :events, :happened_at, :timestamp, default: -> { 'CURRENT_TIMESTAMP' }
    execute "UPDATE events SET happened_at = created_at;"
    change_column_null :events, :happened_at, false
    add_index :events, :happened_at
  end
  def down
    remove_column :events, :happened_at
  end
end
