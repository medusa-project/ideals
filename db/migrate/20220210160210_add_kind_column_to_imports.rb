class AddKindColumnToImports < ActiveRecord::Migration[7.0]
  def up
    add_column :imports, :kind, :integer, null: true
    execute "UPDATE imports SET kind = 0;"
    add_index :imports, :kind
  end
  def down
    remove_column :imports, :kind
  end
end
