class RenameImportsKindColumnToFormat < ActiveRecord::Migration[7.0]
  def change
    rename_column :imports, :kind, :format
  end
end
