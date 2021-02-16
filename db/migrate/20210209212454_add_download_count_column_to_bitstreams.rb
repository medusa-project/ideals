class AddDownloadCountColumnToBitstreams < ActiveRecord::Migration[6.0]
  def change
    add_column :bitstreams, :download_count, :integer, default: 0, null: false
  end
end
