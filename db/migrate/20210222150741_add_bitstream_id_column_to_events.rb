class AddBitstreamIdColumnToEvents < ActiveRecord::Migration[6.0]
  def up
    add_column :events, :bitstream_id, :bigint
    add_foreign_key :events, :bitstreams, on_update: :cascade, on_delete: :cascade
    change_column_null :events, :item_id, true
    remove_column :bitstreams, :download_count
  end

  def down
    add_column :bitstreams, :download_count, :bigint, default: 0
    remove_column :events, :bitstream_id
  end
end
