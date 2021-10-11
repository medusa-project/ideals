class DropBitstreamsMediaType < ActiveRecord::Migration[6.0]
  def change
    remove_column :bitstreams, :media_type
  end
end
