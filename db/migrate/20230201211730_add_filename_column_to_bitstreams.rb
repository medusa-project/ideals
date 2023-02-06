class AddFilenameColumnToBitstreams < ActiveRecord::Migration[7.0]
  def change
    add_column :bitstreams, :filename, :string
    execute "UPDATE bitstreams SET filename = original_filename;"
    add_index :bitstreams, :filename
  end
end
