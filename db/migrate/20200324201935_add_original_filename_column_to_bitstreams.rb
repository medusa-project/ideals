class AddOriginalFilenameColumnToBitstreams < ActiveRecord::Migration[6.0]
  def change
    add_column :bitstreams, :original_filename, :string
  end
end
