class RenameBitstreamsKeyColumn < ActiveRecord::Migration[6.0]
  def change
    rename_column :bitstreams, :key, :staging_key
    change_column_null :bitstreams, :staging_key, true

    add_column :bitstreams, :medusa_key, :string
    add_index :bitstreams, :medusa_key, unique: true
  end
end
