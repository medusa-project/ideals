class AddStageColumnToItems < ActiveRecord::Migration[6.0]
  def up
    add_column :items, :stage, :integer, null: false, default: 0
    add_index :items, :stage
    execute "UPDATE items SET stage = 100 WHERE submitting = true;"
    execute "UPDATE items SET stage = 300 WHERE discoverable = true;"
    execute "UPDATE items SET stage = 400 WHERE withdrawn = true;"
    remove_column :items, :submitting
    remove_column :items, :withdrawn
  end
  def down
    add_column :items, :submitting, :boolean, default: false, null: false
    add_column :items, :withdrawn, :boolean, default: false, null: false
    execute "UPDATE items SET submitting = true WHERE stage = 100;"
    execute "UPDATE items SET withdrawn = true WHERE stage = 400;"
    remove_column :items, :stage
  end
end