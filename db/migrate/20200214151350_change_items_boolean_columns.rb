class ChangeItemsBooleanColumns < ActiveRecord::Migration[6.0]
  def change
    change_column :items, :discoverable, :boolean, null: false, default: false
    change_column :items, :in_archive, :boolean, null: false, default: false
    change_column :items, :withdrawn, :boolean, null: false, default: false

    add_index :items, :discoverable
    add_index :items, :in_archive
    add_index :items, :withdrawn
  end
end
