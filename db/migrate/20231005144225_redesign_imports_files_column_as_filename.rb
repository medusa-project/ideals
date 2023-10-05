class RedesignImportsFilesColumnAsFilename < ActiveRecord::Migration[7.0]
  def change
    remove_column :imports, :files
    add_column :imports, :filename, :string
  end
end
