class DropBitstreamFormats < ActiveRecord::Migration[6.0]
  def change
    drop_table :bitstream_formats
    add_column :bitstreams, :media_type, :string, null: false
    remove_column :bitstreams, :bitstream_format_id
  end
end
