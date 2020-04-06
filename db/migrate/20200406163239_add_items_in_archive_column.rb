class AddItemsInArchiveColumn < ActiveRecord::Migration[6.0]
  def change
    add_column :items, :in_archive, :boolean, default: false, null: false
    add_index :items, :in_archive
  end
end
