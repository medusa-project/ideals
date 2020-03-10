class ReplaceItemsInArchiveColumnWithSubmittingColumn < ActiveRecord::Migration[6.0]
  def up
    add_column :items, :submitting, :boolean, null: false, default: true
    execute "UPDATE items SET submitting = false;"
    add_index :items, :submitting
    remove_column :items, :in_archive
  end
  def down
    remove_column :items, :submitting
    add_column :items, :in_archive, :boolean
  end
end
