class AddArchivedFilesColumnToBistreams < ActiveRecord::Migration[7.0]
  def change
    add_column :bitstreams, :archived_files, :text
  end
end
