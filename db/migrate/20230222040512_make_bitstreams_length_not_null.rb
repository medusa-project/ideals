class MakeBitstreamsLengthNotNull < ActiveRecord::Migration[7.0]
  def change
    execute "UPDATE bitstreams SET length = 0 WHERE length IS NULL;"
    change_column_null :bitstreams, :length, false
    add_index :bitstreams, :length # for statistics sorting
  end
end
